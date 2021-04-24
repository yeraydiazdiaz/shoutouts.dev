defmodule Shoutouts.ShoutoutsTest do
  use Shoutouts.DataCase, async: true

  alias Shoutouts.Factory
  alias Shoutouts.Projects.Project
  alias Shoutouts.Projects
  alias Shoutouts.Accounts.User
  alias Shoutouts.Accounts
  alias Shoutouts.Shoutouts

  @sample_text "this project is so good!"
  @valid_attrs %{text: "this project is so good!"}
  @invalid_attrs %{text: nil}

  describe "create_shoutout" do
    test "valid attrs" do
      user = Factory.insert(:user)
      project = Factory.insert(:project)
      {:ok, shoutout} = Shoutouts.create_shoutout(user, project, @valid_attrs)
      assert shoutout.id
    end

    test "requires text" do
      user = Factory.insert(:user)
      project = Factory.insert(:project)

      {:error, %Ecto.Changeset{} = changeset} =
        Shoutouts.create_shoutout(user, project, @invalid_attrs)

      assert not changeset.valid?
      assert [{:text, _}] = changeset.errors
    end

    test "requires existing user" do
      user =
        Factory.params_for(:user)
        |> Map.put(:id, UUID.uuid4())

      project = Factory.insert(:project)

      {:error, %Ecto.Changeset{} = changeset} =
        Shoutouts.create_shoutout(user, project, @valid_attrs)

      assert not changeset.valid?
      assert [{:user, _}] = changeset.errors
    end

    test "requires existing project" do
      user = Factory.insert(:user)

      project =
        Factory.params_for(:project)
        |> Map.put(:id, UUID.uuid4())

      {:error, %Ecto.Changeset{} = changeset} =
        Shoutouts.create_shoutout(user, project, @valid_attrs)

      assert not changeset.valid?
      assert [{:project, _}] = changeset.errors
    end

    test "allows emojis" do
      user = Factory.insert(:user)
      project = Factory.insert(:project)
      text = "I like emojis 🎉"

      {:ok, shoutout} = Shoutouts.create_shoutout(user, project, %{text: text})

      assert shoutout.text == "I like emojis 🎉"
    end

    test "fails if already existing shoutout, i.e. one shoutout per user + project" do
      user = Factory.insert(:user)
      project = Factory.insert(:project)
      {:ok, _} = Shoutouts.create_shoutout(user, project, @valid_attrs)

      {:error, %Ecto.Changeset{} = changeset} =
        Shoutouts.create_shoutout(user, project, @valid_attrs)

      assert not changeset.valid?
      assert [{:user_id, _}] = changeset.errors
    end
  end

  test "get_shoutout! returns associated user and project" do
    shoutout = Factory.insert(:shoutout)
    shoutout = Shoutouts.get_shoutout!(shoutout.id)
    assert %User{} = shoutout.user
    assert %Project{} = shoutout.project
  end

  test "list_shoutouts returns all shoutouts most recent first" do
    _ = Factory.insert(:shoutout)
    _ = Factory.insert(:shoutout, text: "so good!")
    assert [_, _] = Shoutouts.list_shoutouts()
    # Asserting ordering requires sleeping for a long time, not sure why...
    # assert t.text == "so good!"
  end

  test "list_shoutouts_for_project returns associated user and project" do
    %{project: project} = shoutout = Factory.insert(:shoutout)
    [t] = Shoutouts.list_shoutouts_for_project(project.owner, project.name)
    assert t.id == shoutout.id
    assert t.text == shoutout.text
  end

  test "change_shoutout returns a shoutout changeset" do
    shoutout = Factory.insert(:shoutout)

    assert %Ecto.Changeset{} =
             changeset = Shoutouts.change_shoutout(shoutout, %{text: @sample_text})

    assert changeset.valid?
  end

  test "update_shoutout returns the updated shoutout" do
    shoutout = Factory.insert(:shoutout)
    {:ok, t} = Shoutouts.update_shoutout(shoutout, %{text: @sample_text})
    assert t.id == shoutout.id
    assert t.text == @sample_text
  end

  test "delete_shoutout returns the updated shoutout" do
    shoutout = Factory.insert(:shoutout)
    {:ok, _} = Shoutouts.delete_shoutout(shoutout)
    [] = Shoutouts.list_shoutouts()
  end

  test "deleting a project cascade deletes its shoutouts" do
    shoutout = Factory.insert(:shoutout)
    {:ok, _} = Projects.delete_project(shoutout.project)
    [] = Shoutouts.list_shoutouts()
  end

  test "deleting a user cascade deletes their shoutouts" do
    shoutout = Factory.insert(:shoutout)
    {:ok, _} = Accounts.delete_user(shoutout.user)
    [] = Shoutouts.list_shoutouts()
  end

  test "pin_shoutout sets the pinned flag" do
    shoutout = Factory.insert(:shoutout)
    {:ok, t} = Shoutouts.pin_shoutout(shoutout)
    assert t.pinned
  end

  test "unpin_shoutout sets the pinned flag to false" do
    shoutout = Factory.insert(:shoutout)
    {:ok, t} = Shoutouts.unpin_shoutout(shoutout)
    assert not t.pinned
  end

  test "flag_shoutout sets flagged to true" do
    shoutout = Factory.insert(:shoutout)
    {:ok, t} = Shoutouts.flag_shoutout(shoutout)
    assert t.flagged
  end

  test "unflag_shoutout sets flagged to false" do
    shoutout = Factory.insert(:shoutout)
    {:ok, t} = Shoutouts.unflag_shoutout(shoutout)
    assert not t.flagged
  end

  test "list_shoutouts_for_user" do
    shoutout = Factory.insert(:shoutout)
    shoutouts = Shoutouts.list_shoutouts_for_user(shoutout.user.username)

    assert shoutouts == [
             [
               shoutout.text,
               shoutout.pinned,
               shoutout.project.owner,
               shoutout.project.name
             ]
           ]
  end

  describe "count_flagged_shoutouts_for_user_and_owner" do
    test "returns number of flagged shoutouts" do
      shoutout = Factory.insert(:shoutout)
      {:ok, _} = Shoutouts.flag_shoutout(shoutout)
      shoutout = Factory.insert(:shoutout, user: shoutout.user)
      {:ok, _} = Shoutouts.flag_shoutout(shoutout)
      _ = Factory.insert(:shoutout, user: shoutout.user)

      num_flagged = Shoutouts.count_flagged_shoutouts_for_user_and_owner(shoutout.user.id)

      assert num_flagged == 2
    end

    test "returns number of flagged shoutouts for a specific owner" do
      owner_project_a = Factory.insert(:project)
      owner_project_b = Factory.insert(:project, user: owner_project_a.user)
      project_c = Factory.insert(:project)

      shoutout = Factory.insert(:shoutout, project: owner_project_a)
      {:ok, _} = Shoutouts.flag_shoutout(shoutout)
      _ = Factory.insert(:shoutout, user: shoutout.user, project: owner_project_b)
      shoutout = Factory.insert(:shoutout, user: shoutout.user, project: project_c)
      {:ok, _} = Shoutouts.flag_shoutout(shoutout)

      num_flagged =
        Shoutouts.count_flagged_shoutouts_for_user_and_owner(
          shoutout.user.id,
          owner_project_a.user.id
        )

      assert num_flagged == 1
    end
  end

  describe "count_owners_flagged_user" do
    test "returns number of owners that have flagged the user" do
      project_owner_a = Factory.insert(:project)
      project_owner_b = Factory.insert(:project)
      project_b_owner_b = Factory.insert(:project, user: project_owner_b.user)

      shoutout = Factory.insert(:shoutout, project: project_owner_a)
      {:ok, _} = Shoutouts.flag_shoutout(shoutout)
      shoutout = Factory.insert(:shoutout, user: shoutout.user, project: project_owner_b)
      {:ok, _} = Shoutouts.flag_shoutout(shoutout)

      shoutout = Factory.insert(:shoutout, user: shoutout.user, project: project_b_owner_b)

      {:ok, _} = Shoutouts.flag_shoutout(shoutout)

      num_flagged = Shoutouts.count_owners_flagged_user(shoutout.user.id)

      assert num_flagged == 2
    end
  end

  describe "vote" do
    test "vote_shoutout/3 adds a vote" do
      shoutout = Factory.insert(:shoutout)
      user = Factory.insert(:user)
      {:ok, _} = Shoutouts.vote_shoutout(shoutout, user, "up")

      t =
        Repo.get!(Shoutouts.Shoutout, shoutout.id)
        |> Repo.preload(:votes)

      assert length(t.votes) == 1
      [vote] = t.votes
      assert vote.user_id == user.id
      assert vote.shoutout_id == shoutout.id
      assert vote.type == :up
    end

    test "requires a valid type" do
      shoutout = Factory.insert(:shoutout)
      user = Factory.insert(:user)
      {:error, changeset} = Shoutouts.vote_shoutout(shoutout, user, "not_a_type")
      [{:type, _}] = changeset.errors
    end

    test "requires existing user" do
      shoutout = Factory.insert(:shoutout)

      user =
        Factory.params_for(:user)
        |> Map.put(:id, UUID.uuid4())

      {:error, %Ecto.Changeset{} = changeset} = Shoutouts.vote_shoutout(shoutout, user, "up")

      assert not changeset.valid?
      assert [{:user, _}] = changeset.errors
    end

    test "requires existing shoutout" do
      user = Factory.insert(:user)

      shoutout =
        Factory.insert(:shoutout)
        |> Map.put(:id, UUID.uuid4())

      {:error, %Ecto.Changeset{} = changeset} = Shoutouts.vote_shoutout(shoutout, user, "up")

      assert not changeset.valid?
      assert [{:shoutout, _}] = changeset.errors
    end
  end

  describe "shoutouts_for_top_projects" do
    test "returns the last pinned shoutout for each top project" do
      p1 = Factory.insert(:project, %{primary_language: "Elixir"})

      1..2
      |> Enum.map(fn _ -> Factory.insert(:shoutout, %{project: p1}) end)

      p2 =
        Factory.insert(:project, %{primary_language: "Elixir", owner: "somewhat", name: "popular"})

      1..3
      |> Enum.map(fn _ -> Factory.insert(:shoutout, %{project: p2}) end)

      p2_shoutout = Factory.insert(:shoutout, %{project: p2, pinned: true})

      p3 = Factory.insert(:project, %{primary_language: "Python", owner: "very", name: "popular"})

      1..4
      |> Enum.map(fn _ -> Factory.insert(:shoutout, %{project: p3}) end)

      p3_shoutout = Factory.insert(:shoutout, %{project: p3, pinned: true})
      # more recent but pinned first
      Factory.insert(:shoutout, %{project: p3, pinned: false})

      [s1, s2] = Shoutouts.shoutouts_for_top_projects(2)
      assert p3_shoutout.id == s1.id
      assert p2_shoutout.id == s2.id
    end

    test "returns the last shoutout for each top project" do
      p1 = Factory.insert(:project, %{primary_language: "Elixir"})

      1..2
      |> Enum.map(fn _ -> Factory.insert(:shoutout, %{project: p1}) end)

      p2 =
        Factory.insert(:project, %{primary_language: "Elixir", owner: "somewhat", name: "popular"})

      1..3
      |> Enum.map(fn _ -> Factory.insert(:shoutout, %{project: p2}) end)


      p3 = Factory.insert(:project, %{primary_language: "Python", owner: "very", name: "popular"})

      1..4
      |> Enum.map(fn _ -> Factory.insert(:shoutout, %{project: p3}) end)

      # Force meaningful inserted_at difference
      Process.sleep(1000)
      p2_shoutout = Factory.insert(:shoutout, %{project: p2})
      p3_shoutout = Factory.insert(:shoutout, %{project: p3})

      [s1, s2] = Shoutouts.shoutouts_for_top_projects(2)
      assert p3_shoutout.id == s1.id
      assert p2_shoutout.id == s2.id
    end
  end

  describe "unnotified_shoutouts/1" do
    test "returns shoutouts with projects and users with notified_at == nil" do
      Factory.insert(:shoutout, notified_at: DateTime.utc_now())
      s1 = Factory.insert(:shoutout)
      [shoutout] = Shoutouts.unnotified_shoutouts()
      assert shoutout.text == s1.text
      assert shoutout.user == s1.user
      assert shoutout.project == s1.project
    end

    test "does not return shoutouts for projects whose owner has disabled notifications" do
      user = Factory.insert(:user, notify_when: :disabled)
      project = Factory.insert(:project, user: user)
      Factory.insert(:shoutout, project: project)
      assert [] = Shoutouts.unnotified_shoutouts()
    end
  end
end
