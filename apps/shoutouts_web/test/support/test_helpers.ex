defmodule ShoutoutsWeb.TestHelpers do

  def auth_for_user(user) do
    %Ueberauth.Auth{
      info: %Ueberauth.Auth.Info{
        email: user.email,
        name: user.name,
        nickname: user.username,
        image: "https://example.org/avatar/#{user.username}",
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
      strategy: Ueberauth.Strategy.Github,
    }
  end
end
