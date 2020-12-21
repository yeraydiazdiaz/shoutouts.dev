# mix run <THIS_FILE>

# TODO: progress bar https://github.com/henrik/progress_bar

alias Shoutouts.GitHubApp
[login, _limit] = ["yeraydiazdiaz", 2]
client = GitHubApp.app_client(Application.get_env(:shoutouts, :github_token))
{:ok, repos} = GitHubApp.user_starred_repos(client, login)

project_data =
  repos
  # |> Stream.take(limit)
  |> Stream.map(&GitHubApp.project_info(client, &1))
  |> Stream.map(fn {:ok, data} -> data end)
  |> Enum.to_list()

content = Jason.encode!(project_data)
projects_path = Path.join(Path.dirname(__ENV__.file), "./projects.json")
File.write!(projects_path, content)
