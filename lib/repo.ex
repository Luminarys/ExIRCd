defmodule ExIRCd.Repo do
  use Ecto.Repo, otp_app: :exircd
end

defmodule Channel do
  use Ecto.Model
  schema "channels" do
    belongs_to :owner, User
    belongs_to :topic, Topic
    has_many :bans, ChanBan
  end
end

defmodule User do
  use Ecto.Model
  schema "users" do
    has_many :channels, Channel
    field :nick, :string
    field :email, :string
    field :password, :string
  end
end

defmodule Topic do
  use Ecto.Model
  schema "topics" do
    has_one :channel, Channel
    field :text, :string
    field :setter, :string
    timestamps
  end
end

defmodule ChanBan do
  use Ecto.Model
  schema "chanbans" do
    field :mask, :string
    field :setter, :string
    belongs_to :channel, Channel
    timestamps
  end
end
