defmodule ShoutoutsWeb.EmailTest do
  use ShoutoutsWeb.ConnCase

  alias Shoutouts.Factory

  describe "Email" do
    test "shoutout_digest" do
      user = Factory.insert(:user, name: "Yeray Diaz Diaz")
      email = ShoutoutsWeb.Email.shoutout_digest(user)
      assert email.to == user.email
      assert email.from == "no-reply@shoutouts.dev"
      assert email.subject == "New shoutouts for your projects"
      assert email.text_body =~ "Hi Yeray"
    end
  end
end
