defmodule Shoutouts.ProjectsTest do
  use Shoutouts.DataCase, async: true

  import Mox
  setup :verify_on_exit!

  alias Shoutouts.Factory
  alias Shoutouts.Projects
  alias Shoutouts.Projects.Project

  test "projects are associated with a user" do
    _ = Factory.insert(:project)

    [project] = Projects.list_projects()

    assert project.user
    assert not project.pinned_only
  end

  test "we can fetch a user's projects" do
    user = Factory.insert(:user)

    1..3
    |> Enum.each(fn _ -> Factory.insert(:project, %{user: user}) end)

    projects = Projects.list_projects_for_username(user.username)

    assert length(projects) == 3
    [first, _, last] = projects
    assert first.inserted_at <= last.inserted_at
  end

  test "change_project/1 returns a project changeset" do
    project = Factory.insert(:project)
    assert %Ecto.Changeset{} = Projects.change_project(project)
  end

  test "create_project/1 returns a persisted project" do
    user = Factory.insert(:user)
    params = Factory.params_for(:project, owner: "me", name: "mine")
    {:ok, project} = Projects.create_project(user, params)
    assert project.id
    assert [project] = Projects.list_projects()
    assert Projects.name_with_owner(project) == "me/mine"
  end

  test "update_project/2 with valid data updates the project" do
    project = Factory.insert(:project)
    assert {:ok, %Project{} = project} = Projects.update_project(project, %{pinned_only: true})
    assert project.pinned_only == true
  end

  test "update_project/2 with invalid data returns error changeset" do
    project = Factory.insert(:project)

    assert {:error, %Ecto.Changeset{} = changeset} =
             Projects.update_project(project, %{pinned_only: nil})

    [{:pinned_only, _}] = changeset.errors
    assert project.pinned_only == false
  end

  test "delete_project/1 deletes the project" do
    project = Factory.insert(:project)
    assert {:ok, %Project{}} = Projects.delete_project(project)
    assert_raise Ecto.NoResultsError, fn -> Projects.get_project!(project.id) end
  end

  test "owner + name must be unique" do
    project = Factory.insert(:project)
    other_project = Factory.params_for(:project, %{name: project.name, owner: project.owner})
    {:error, changeset} = Projects.create_project(project.user, other_project)
    [{:owner, _}] = changeset.errors
  end

  describe "get_project_by_owner_and_name!" do
    test "raises if project does not exist" do
      assert_raise Ecto.NoResultsError, fn ->
        Projects.get_project_by_owner_and_name!("does not", "exist")
      end
    end

    test "returns projects with shoutouts with correct order" do
      project = Factory.insert(:project)

      Factory.insert(:shoutout, %{project: project, user: Factory.insert(:user)})
      Factory.insert(:shoutout, %{project: project, user: Factory.insert(:user), pinned: true})

      project = Projects.get_project_by_owner_and_name!(project.owner, project.name)

      [first, _] = project.shoutouts
      assert first.pinned
    end
  end

  test "project_summary_for_username" do
    project = Factory.insert(:project)

    1..3
    |> Enum.each(fn _ -> Factory.insert(:shoutout, %{project: project}) end)

    projects = Projects.project_summary_for_username(project.user.username)

    assert projects == [[project.id, project.owner, project.name, 3]]
  end

  test "top_languages_by_projects" do
    1..3
    |> Enum.each(fn _ -> Factory.insert(:project, %{primary_language: "Elixir"}) end)

    1..2
    |> Enum.each(fn _ -> Factory.insert(:project, %{primary_language: "Python"}) end)

    Factory.insert(:project, %{primary_language: "javascript"})

    summary = Projects.top_languages_by_projects(2)

    assert summary == [["Elixir", 3], ["Python", 2]]
  end

  test "top_projects_by_language_and_shoutouts" do
    p1 = Factory.insert(:project, %{primary_language: "Elixir"})

    1..2
    |> Enum.map(fn _ -> Factory.insert(:shoutout, %{project: p1}) end)

    p2 = Factory.insert(:project, %{primary_language: "Elixir"})

    1..3
    |> Enum.map(fn _ -> Factory.insert(:shoutout, %{project: p2}) end)

    p3 = Factory.insert(:project, %{primary_language: "Python"})

    1..5
    |> Enum.map(fn _ -> Factory.insert(:shoutout, %{project: p3}) end)

    summary = Projects.top_projects_by_language_and_shoutouts("Elixir", 1)

    assert summary == [[p2.owner, p2.name, 3]]
  end

  test "summary_by_languages" do
    p1 = Factory.insert(:project, %{primary_language: "Elixir"})

    1..2
    |> Enum.map(fn _ -> Factory.insert(:shoutout, %{project: p1}) end)

    p2 = Factory.insert(:project, %{primary_language: "Elixir"})

    1..3
    |> Enum.map(fn _ -> Factory.insert(:shoutout, %{project: p2}) end)

    p3 = Factory.insert(:project, %{primary_language: "Python"})

    1..5
    |> Enum.map(fn _ -> Factory.insert(:shoutout, %{project: p3}) end)

    summary = Projects.summary_by_languages(1, 2)

    assert summary == [
             ["Elixir", 2, [[p2.owner, p2.name, 3], [p1.owner, p1.name, 2]]]
           ]
  end

  describe "list_with_owners_and_names" do
    test "returns empty list if no projects match" do
      owners_and_names = [["alice", "p1"]]

      _ = Factory.insert(:project)

      assert Projects.list_with_owners_and_names(owners_and_names) == []
    end

    test "returns only matching projects" do
      owners_and_names = [["alice", "p1"], ["bob", "p2"]]

      owners_and_names
      |> Enum.each(fn [owner, name] -> Factory.insert(:project, %{name: name, owner: owner}) end)

      _ = Factory.insert(:project)

      [p1, p2] = Projects.list_with_owners_and_names(owners_and_names)
      assert p1.owner == "alice"
      assert p1.name == "p1"
      assert p2.owner == "bob"
      assert p2.name == "p2"
    end
  end

  describe "refresh project" do
    test "updates project information" do
      project = Factory.insert(:project, description: "Old description")

      Shoutouts.MockProvider
      |> expect(:client, fn -> Tesla.Client end)

      Shoutouts.MockProvider
      |> expect(:project_info, fn _client, _owner, _name ->
        {:ok,
         %Shoutouts.Providers.ProviderProject{
           description: "New description",
           provider_id: project.provider_id,
           owner: project.owner,
           name: project.name,
           url: project.url,
           primary_language: project.primary_language
         }}
      end)

      {:ok, updated_project} = Projects.refresh_project(project)

      assert updated_project.description == "New description"
    end

    test "does not update project on error" do
      project = Factory.insert(:project, description: "Old description")

      Shoutouts.MockProvider
      |> expect(:client, fn -> Tesla.Client end)

      Shoutouts.MockProvider
      |> expect(:project_info, fn _client, _owner, _name ->
        {:error, %Tesla.Env{status: 500}}
      end)

      {:error, _} = Projects.refresh_project(project)
      assert Projects.get_project!(project.id) == project
    end
  end

  describe "refresh projects" do
    test "updates projects from data in provider's API" do
      project = Factory.insert(:project, description: "Old description")

      Shoutouts.MockProvider
      |> expect(:client, fn -> Tesla.Client end)

      Shoutouts.MockProvider
      |> expect(:project_info, fn _client, _owner, _name ->
        {:ok,
         %Shoutouts.Providers.ProviderProject{
           description: "New description",
           provider_id: project.provider_id,
           owner: project.owner,
           name: project.name,
           url: project.url,
           primary_language: project.primary_language
         }}
      end)

      {:ok, errors} = Projects.refresh_projects(0)

      assert errors == []
      updated_project = Projects.get_project!(project.id)
      assert updated_project.description == "New description"
    end

    test "returns a list of project IDs that generated errors" do
      project = Factory.insert(:project, description: "Old description")

      Shoutouts.MockProvider
      |> expect(:client, fn -> Tesla.Client end)

      Shoutouts.MockProvider
      |> expect(:project_info, fn _client, _owner, _name ->
        {:error, "Boom!"}
      end)

      {:error, errors} = Projects.refresh_projects(0)

      assert errors == [project.id]
    end

    test "updates a number of projects if provided" do
      project_to_update = Factory.insert(:project, description: "Old description")
      project_not_to_update = Factory.insert(:project)

      Shoutouts.MockProvider
      |> expect(:client, fn -> Tesla.Client end)

      Shoutouts.MockProvider
      |> expect(:project_info, fn _client, _owner, _name ->
        {:ok,
         %Shoutouts.Providers.ProviderProject{
           description: "New description",
           provider_id: project_to_update.provider_id,
           owner: project_to_update.owner,
           name: project_to_update.name,
           url: project_to_update.url,
           primary_language: project_to_update.primary_language
         }}
      end)

      {:ok, errors} = Projects.refresh_projects(0, 1)

      assert errors == []
      updated_project = Projects.get_project!(project_to_update.id)
      assert updated_project.description == "New description"
      not_updated_project = Projects.get_project!(project_not_to_update.id)
      assert not_updated_project.description == project_not_to_update.description
    end

    test "only updates projects with updated_at older than specified days" do
      project = Factory.insert(:project, description: "Old description")

      {:ok, errors} = Projects.refresh_projects(1)

      assert errors == []
      not_updated_project = Projects.get_project!(project.id)
      assert not_updated_project.description == project.description
    end
  end

  describe "validate_registration" do
    test "returns error for already registered projects" do
      project = Factory.insert(:project)
      {:error, :already_exists} = Projects.validate_registration(project.owner, project.name)
    end

    test "returns error for non-existing projects in the provider" do
      Shoutouts.MockProvider
      |> expect(:client, fn -> Tesla.Client end)

      Shoutouts.MockProvider
      |> expect(:project_info, fn _client, _owner, _name ->
        {:ok, :no_such_repo}
      end)

      {:error, :no_such_repo} =
        Projects.validate_registration("doesnot", "exist", Shoutouts.MockProvider)
    end

    test "returns error for error fetching project information" do
      Shoutouts.MockProvider
      |> expect(:client, fn -> Tesla.Client end)

      Shoutouts.MockProvider
      |> expect(:project_info, fn _client, _owner, _name ->
        {:error, %Tesla.Env{status: 500}}
      end)

      {:error, :provider_error} =
        Projects.validate_registration("yeraydiazdiaz", "shoutouts.dev", Shoutouts.MockProvider)
    end

    test "returns {:ok, provider_project} for projects that are not yet registered and exist in the provider" do
      Shoutouts.MockProvider
      |> expect(:client, fn -> Tesla.Client end)

      provider_project = Factory.provider_project_factory()

      Shoutouts.MockProvider
      |> expect(:project_info, fn _client, _owner, _name ->
        {:ok, provider_project}
      end)

      {:ok, pi} =
        Projects.validate_registration("yeraydiazdiaz", "shoutouts.dev", Shoutouts.MockProvider)

      assert pi == provider_project
    end
  end
end
