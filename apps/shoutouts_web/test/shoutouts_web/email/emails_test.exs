defmodule ShoutoutsWeb.EmailsTest do
  use ShoutoutsWeb.ConnCase
  use Bamboo.Test

  alias Shoutouts.Factory
  alias ShoutoutsWeb.Email.Emails

  describe "shoutout_digest" do
    test "no shoutouts, no emails" do
      assert [] = Emails.shoutout_digest()
    end

    test "single project, > 2 shoutouts" do
      user = Factory.insert(:user, name: "Yeray Diaz Diaz")
      project = Factory.insert(:project, user: user)
      shoutouts = for _ <- 1..3, do: Factory.insert(:shoutout, project: project)
      [{email, _}] = Emails.shoutout_digest()

      assert email.to == user.email
      assert email.from == "no-reply@shoutouts.dev"
      assert email.subject == "New shoutouts for your projects"

      project_url =
        Routes.project_show_url(ShoutoutsWeb.Endpoint, :show, project.owner, project.name)

      assert [_] = Floki.find(email.html_body, "a[href=\"#{project_url}\"]")

      combinations =
        for x <- shoutouts,
            y <- shoutouts,
            x.user.name != y.user.name,
            do: "#{x.user.name}, #{y.user.name}"

      assert Enum.any?(combinations, fn combination -> email.html_body =~ combination end)
      assert email.html_body =~ "and 1 other people"

      assert email.text_body =~
               Routes.project_show_url(ShoutoutsWeb.Endpoint, :show, project.owner, project.name)

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

      emails_and_shoutouts = Emails.shoutout_digest()

      assert length(emails_and_shoutouts) == 2
      emails = Enum.map(emails_and_shoutouts, fn {email, _} -> email end)
      assert Enum.all?(emails, &(&1.from == "no-reply@shoutouts.dev"))
      assert Enum.all?(emails, &(&1.subject == "New shoutouts for your projects"))
      # Match emails to users, since the query is not ordered
      assert email1 = Enum.find(emails, &(&1.to == user1.email))
      assert email2 = Enum.find(emails, &(&1.to == user2.email))

      assert email1.html_body =~ "Hi Yeray"

      assert email1.html_body =~
               Routes.project_show_url(
                 ShoutoutsWeb.Endpoint,
                 :show,
                 project1.owner,
                 project1.name
               )

      assert email1.html_body =~ shoutout1.user.name

      assert email2.html_body =~ "Hi Phil"

      assert email2.html_body =~
               Routes.project_show_url(
                 ShoutoutsWeb.Endpoint,
                 :show,
                 project2.owner,
                 project2.name
               )

      assert email2.html_body =~ shoutout2a.user.name
      assert email2.html_body =~ shoutout2b.user.name
    end
  end

  describe "send_and_update_shoutouts" do
    test "no errors" do
      user = Factory.insert(:user, name: "Yeray Diaz Diaz")
      project = Factory.insert(:project, user: user)
      shoutouts = for _ <- 1..3, do: Factory.insert(:shoutout, project: project)
      [{email, _shoutouts}] = Emails.shoutout_digest()

      {:ok, _response} = Emails.send_and_update_shoutouts(email, shoutouts)

      assert_delivered_email(email)
      updated_shoutouts = Enum.map(shoutouts, &Shoutouts.Shoutouts.get_shoutout!(&1.id))
      assert Enum.all?(updated_shoutouts, &(&1.notified_at != nil))
    end

    test "successive calls do not yield shoutouts" do
      project = Factory.insert(:project)
      for _ <- 1..3, do: Factory.insert(:shoutout, project: project)
      [{email, shoutouts}] = Emails.shoutout_digest()
      {:ok, _response} = Emails.send_and_update_shoutouts(email, shoutouts)
      assert [] = Emails.shoutout_digest()
    end
  end
end
