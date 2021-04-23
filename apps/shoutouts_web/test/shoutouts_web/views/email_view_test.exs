defmodule ShoutoutsWeb.EmailTest do
  use ShoutoutsWeb.ConnCase

  alias Shoutouts.Factory

  describe "shoutout_digest" do
    test "no shoutouts, no emails" do
      assert [] = ShoutoutsWeb.Email.shoutout_digest()
    end

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

    test "2 projects, 1 and 2 shoutouts" do
      user1 = Factory.insert(:user, name: "Yeray Diaz Diaz")
      user2 = Factory.insert(:user, name: "Phil Jones")
      project1 = Factory.insert(:project, user: user1)
      project2 = Factory.insert(:project, user: user2)
      shoutout1 = Factory.insert(:shoutout, project: project1)
      shoutout2a = Factory.insert(:shoutout, project: project2)
      shoutout2b = Factory.insert(:shoutout, project: project2)

      emails = ShoutoutsWeb.Email.shoutout_digest()

      assert length(emails) == 2
      assert Enum.all?(emails, &(&1.from == "no-reply@shoutouts.dev"))
      assert Enum.all?(emails, &(&1.subject == "New shoutouts for your projects"))
      # Match emails to users, since the query is not ordered
      assert email1 = Enum.find(emails, &(&1.to == user1.email))
      assert email2 = Enum.find(emails, &(&1.to == user2.email))

      assert email1.html_body =~ "Hi Yeray"
      assert email1.html_body =~ Routes.project_show_url(ShoutoutsWeb.Endpoint, :show, project1.owner, project1.name)
      assert email1.html_body =~ shoutout1.user.name

      assert email2.html_body =~ "Hi Phil"
      assert email2.html_body =~ Routes.project_show_url(ShoutoutsWeb.Endpoint, :show, project2.owner, project2.name)
      assert email2.html_body =~ shoutout2a.user.name
      assert email2.html_body =~ shoutout2b.user.name
    end
  end
end
