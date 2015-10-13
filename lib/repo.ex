defmodule ExIRCd.Repo do
  use Ecto.Repo, otp_app: :exircd
end

defmodule Channel do
  @moduledoc """
  An IRC channel. It can have an owner,
  topic, and bans.
  """
  use Ecto.Model
  schema "channels" do
    belongs_to :owner, User
    belongs_to :topic, Topic
    has_many :bans, ChanBan
  end
end

defmodule User do
  @moduledoc """
  A registered IRC user. Users have a nick, email,
  and password.
  """
  use Ecto.Model
  schema "users" do
    has_many :channels, Channel
    field :nick, :string
    field :email, :string
    field :password, :string
  end
end

defmodule Topic do
  @moduledoc """
  A channel topic. It has the text, the hostmask
  of the person who set it, and a timestamp.
  """
  use Ecto.Model
  schema "topics" do
    has_one :channel, Channel
    field :text, :string
    field :setter, :string
    timestamps
  end
end

defmodule ChanBan do
  @moduledoc """
  A channel ban. It has a hostmask to ban, the hostmask of the
  person who set it, the channel it applies to, and a timestamp.
  """
  use Ecto.Model
  schema "chanbans" do
    field :mask, :string
    field :setter, :string
    belongs_to :channel, Channel
    timestamps
  end
end
