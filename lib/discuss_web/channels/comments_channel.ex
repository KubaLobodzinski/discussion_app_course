defmodule DiscussWeb.CommentsChannel do
  use DiscussWeb, :channel

  import Ecto
  alias Discuss.Topic
  alias Discuss.Repo
  alias Discuss.Comment

  @impl true
  def join("comments:" <> topic_id, payload, socket) do
    if authorized?(payload) do
      topic_id = String.to_integer(topic_id)
      topic = Topic
        |> Repo.get(topic_id)
        |> Repo.preload(:comments)

      {:ok, %{comments: topic.comments}, assign(socket, :topic, topic)}
    else
      {:error, %{reason: "unauthorized"}}
    end
  end

  @impl true
  def handle_in(_name, %{"content" => content}, socket) do
    topic = socket.assigns.topic

    changeset = topic
    |> build_assoc(:comments)
    |> Comment.changeset(%{content: content})

    case Repo.insert(changeset) do
      {:ok, _comment} ->
        {:reply, :ok, socket}
      {:error, _reason} ->
        {:reply, {:error, %{errors: changeset}}, socket}
    end

  end

  @impl true
  def handle_in("shout", payload, socket) do
    broadcast(socket, "shout", payload)
    {:noreply, socket}
  end

  defp authorized?(_payload) do
    true
  end
end
