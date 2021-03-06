class User

  include Mongoid::Document
  include Mongoid::Timestamps

  # Bignum extended in Root/lib/mongoid_ext.rb
  field :uid, type: Bignum
  field :name, type: String
  field :email, type: String

  has_many :items, inverse_of: :user, order: :updated_at.desc
  has_and_belongs_to_many :tags, index: true, order: :name.asc

  has_and_belongs_to_many :stocks,
    class_name: "Item",
    inverse_of: :stocked_users,
    index: true,
    order: :updated_at.desc

  has_and_belongs_to_many :followings,
    class_name: "User",
    inverse_of: :followers,
    index: true,
    order: :email.asc

  has_and_belongs_to_many :followers,
    class_name: "User",
    inverse_of: :followings,
    index: true,
    order: :email.asc

  index({uid: 1}, unique: true)
  index({email: 1,}, unique: true)

  validates :uid, presence: true
  validates :name, presence: true
  validates :email, presence: true, uniqueness: true
  validate :uniqueness_of_uid, if: :new_record?


  class << self
    def find_or_create_from_auth(auth)
      find_from_auth(auth) || create_from_auth(auth)
    end

    def find_by_part_of(email)
      expanded = email + "@" + Settings.email_domain
      find_by(email: expanded)
    end

    def validate_domain(auth)
      auth[:info][:email].match /@#{Settings.email_domain}$/
    end

    private

    def find_from_auth(auth)
      where(uid: auth[:uid]).first
    end

    def create_from_auth(auth)
      addition = {
        email: auth[:info][:email],
        name: auth[:info][:name],
      }
      create(auth.merge(addition))
    end
  end


  def following_items
    Item.order_by(:updated_at.desc)
      .or(:tag_ids.in => tags.map {|tag| tag.id })
      .or(:user_id.in => followings.map {|user| user.id }.push(id))
  end

  def follow(other)
    case other
    when User
      follow_user(other)
    when Tag
      follow_tag(other)
    end
  end

  def unfollow(other)
    case other
    when User
      unfollow_user(other)
    when Tag
      unfollow_tag(other)
    end
  end

  def following?(other)
    case other
    when User
      followings.include? other
    when Tag
      tags.include? other
    end
  end

  def stock(item)
    stocks.push item unless stocks.include? item
  end

  def unstock(item)
    stocks.delete item if stocks.include? item
  end

  def to_param
    email.split("@").first
  end

  private

  def follow_user(other)
    followings.push other unless followings.include? other
  end

  def follow_tag(tag)
    tags.push tag unless tags.include? tag
  end

  def unfollow_user(other)
    followings.delete other if followings.include? other
  end

  def unfollow_tag(tag)
    tags.delete tag if tags.include? tag
  end

  def uniqueness_of_uid
    errors.add(:unique_uid, "uid: #{uid} is not unique.") if self.class.where(uid: uid).count > 0
  end

end
