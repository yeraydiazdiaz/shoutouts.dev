defmodule ShoutoutsWeb.Email do
  use Bamboo.Phoenix, view: ShoutoutsWeb.EmailView

  @default_sender "no-reply@shoutouts.dev"

  def shoutout_digest() do
    Shoutouts.Shoutouts.unnotified_shoutouts()
    |> Enum.group_by(&(&1.project.user))
    |> Enum.map(fn {project, shoutouts} -> shoutout_digest_for_user(project, shoutouts) end)
  end

  def shoutout_digest_for_user(%Shoutouts.Accounts.User{} = user, shoutouts) do
    user_names = (for s <- shoutouts, into: MapSet.new(), do: s.user.name) |> MapSet.to_list
    project_owner_names = shoutouts
      |> Enum.map(fn s -> {s.project.owner, s.project.name} end)
    new_email(
      to: user.email,
      from: @default_sender,
      subject: "New shoutouts for your projects"
    )
    |> put_html_layout({ShoutoutsWeb.LayoutView, "email.html"})
    |> assign(:first_name, Shoutouts.Accounts.first_name(user))
    |> assign(:user_names, user_names)
    |> assign(:project_owner_names, project_owner_names)
    |> render(:shoutouts_digest)
  end
end
