defmodule ShoutoutsWeb.EmailTest do
  use ShoutoutsWeb.ConnCase

  alias Shoutouts.Factory

  describe "shoutout_digest" do
    test "single project, > 2 shoutouts" do
      user = Factory.insert(:user, name: "Yeray Diaz Diaz")
      project = Factory.insert(:project, user: user)
      shoutouts = for _ <- 1..3, do: Factory.insert(:shoutout, project: project)
      [email] = ShoutoutsWeb.Email.shoutout_digest()

      assert email.to == user.email
      assert email.from == "no-reply@shoutouts.dev"
      assert email.subject == "New shoutouts for your projects"

      assert email.html_body =~ Routes.project_show_url(ShoutoutsWeb.Endpoint, :show, project.owner, project.name)
      combinations = for x <- shoutouts,
        y <- shoutouts, x.user.name != y.user.name,
        do: "#{x.user.name}, #{y.user.name}"
      assert Enum.any?(combinations, fn combination -> email.html_body =~ combination end)
      assert email.html_body =~ "and 1 other people"

      assert email.text_body =~ Routes.project_show_url(ShoutoutsWeb.Endpoint, :show, project.owner, project.name)
      assert Enum.any?(combinations, fn combination -> email.text_body =~ combination end)
      assert email.text_body =~ "and 1 other people"
    end
  end
end
