defmodule Shoutouts.AccountsTest do
  use Shoutouts.DataCase, async: true

  alias Shoutouts.Factory
  alias Shoutouts.Accounts
  alias Shoutouts.Accounts.User

  @ueberauth_success %Ueberauth.Auth{
    info: %Ueberauth.Auth.Info{
      email: "user@example.org",
      name: "John Doe",
      nickname: "johndoe",
      image: "https://example.org/avatar/"
    },
    extra: %{
      raw_info: %{
        user: %{
          "created_at" => "2014-02-20T16:58:32Z"
        }
      }
    },
    provider: :github,
    uid: 1234,
    strategy: Ueberauth.Strategy.Github
  }

  @valid_attrs %{
    username: "test",
    email: "test@example.org",
    name: "Yeray",
    avatar_url: "https://example.org/avatar/",
    provider: "github",
    provider_id: "1234",
    provider_joined_at: ~U[2014-02-20T16:58:32Z]
  }

  describe "create_user" do
    test "requires email" do
      assert {:error, _user} = Accounts.create_user(%{username: "test"})
    end

    test "requires valid email" do
      assert {:error, _user} = Accounts.create_user(%{username: "test", email: "invalid@"})
    end

    test "requires username" do
      assert {:error, _user} = Accounts.create_user(%{username: "test@example.org"})
    end

    test "creates a user" do
      assert {:ok, user} = Accounts.create_user(@valid_attrs)
      assert user.id
      assert user.username == "test"
      assert user.email == "test@example.org"
    end
  end

  describe "create_user_from_auth" do
    test "creates a user" do
      assert {:ok, _user} = Accounts.create_user_from_auth(@ueberauth_success)
    end

    test "returns errors if user with the same provider_id exists" do
      user = Factory.insert(:user)

      auth = %Ueberauth.Auth{
        info: %Ueberauth.Auth.Info{
          email: "user@example.org",
          name: "John Doe",
          nickname: "johndoe",
          image: "https://example.org/avatar/"
        },
        extra: %{
          raw_info: %{
            user: %{
              "created_at" => "2014-02-20T16:58:32Z"
            }
          }
        },
        provider: :github,
        uid: user.provider_id,
        strategy: Ueberauth.Strategy.Github
      }

      assert {:error, _} = Accounts.create_user_from_auth(auth)
    end
  end

  test "get_or_create_user_from_auth returns an existing user" do
    user = Factory.insert(:user)

    auth = %{
      info: %{
        email: user.email,
        # TODO: should we update in this case?
        name: "Some Other Name",
        nickname: user.username
      },
      uid: user.provider_id
    }

    assert {:ok, returned_user} = Accounts.get_or_create_user_from_auth(auth)
    assert user.email == returned_user.email
  end

  describe "list_users" do
    test "returns all users" do
      1..3
      |> Enum.each(fn _ -> Factory.insert(:user) end)

      users = Accounts.list_users()
      assert length(users) == 3
    end
  end

  test "get_user!" do
    user = Factory.insert(:user)
    assert _ = Accounts.get_user!(user.id)
  end

  test "get_user_by_email" do
    user = Factory.insert(:user)
    assert _ = Accounts.get_user_by_email(user.email)
  end

  test "change_user/1 returns a user changeset" do
    user = Factory.insert(:user)
    assert %Ecto.Changeset{} = Accounts.change_user(user, %{email: "another@example.org"})
  end

  test "update_user/2 with valid data updates the user" do
    user = Factory.insert(:user)
    assert {:ok, %User{} = user} = Accounts.update_user(user, %{email: "another@example.org"})
    assert user.email == "another@example.org"
  end

  test "update_user/2 with invalid data returns error changeset" do
    user = Factory.insert(:user)

    assert {:error, %Ecto.Changeset{} = changeset} = Accounts.update_user(user, %{username: nil})

    [{:username, _}] = changeset.errors
  end

  test "delete_user/1 deletes the user" do
    user = Factory.insert(:user)
    assert {:ok, %User{}} = Accounts.delete_user(user)
    assert_raise Ecto.NoResultsError, fn -> Accounts.get_user!(user.id) end
  end

  test "first_name/1 returns the guessed first name" do
    user = Factory.insert(:user, name: "Yeray Diaz Diaz")
    assert Accounts.first_name(user) == "Yeray"
  end
end
