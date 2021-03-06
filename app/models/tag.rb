class Tag

  include Mongoid::Document
  field :name, type: String

  has_and_belongs_to_many :users, index: true, order: :email.asc

  has_and_belongs_to_many :items,
    index: true,
    order: :updated_at.desc

  index name: 1
  scope :by_name, order_by(name: 1)

  validates :name, presence: true, uniqueness: true

  def to_param
    name
  end

end
