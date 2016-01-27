require 'digest/sha1'
require 'date'

class Branch
  attr_accessor :commits
  def initialize(name = :master)
    @name = name
    @commits = {}
  end

  def create(branch_name)
    Branch.new(branch_name)
    repository[branch_name] = @commits
  end

  def check(check_branches, check_current, branch_name)
    message = "Branch #{branch_name} does not exist."
    if check_branches == true and check_current == false
      repository.delete(branch_name)
      Objects.new(branch_name, "",true, "Removed branch #{branch_name}")
    elsif check_branches and check_current
      Objects.new(branch_name, "", false, "Cannot remove current branch.")
    else Objects.new(branch_name, "", false, message)
    end
  end

  def remove(branch_name)
    check_branches = repository.include?(branch_name)
    check_current = branch_name.eql?(current)
    check(check_branches, check_current, branch_name)
  end
end

class ObjectStore < Branch
  attr_accessor :repository, :current
  def initialize
    @repository = {}
    @current = Branch.new
  end

  def self.init(&block)
    new_repository = ObjectStore.new
    if block_given?
      new_repository.instance_eval &block
    else new_repository
    end
  end

  def add(name, object)
    changes[name] = object
    message = "Added #{name} to stage."
    Objects.new(name, object, true, message)
  end

  def branch
    @current
  end

  def commit(message)
    commits[Digest::SHA1.hexdigest(message)] = changes
    if changes.size == 0
      text = "Nothing to commit, working directory clean."
      Objects.new("", "", false, text)
    else text = "#{message}" + '\n' + '\t' + "#{commits.size} objects changed"
      Objects.new("", "", true, text)
   end
  end

  def remove(name)
    result = changes.delete(name) {"not found"}
    if result.eql?("not found")
      message = "Object #{name} is not committed."
      Objects.new(name, "", false, message)
    else message = "Added #{name} for removal."
      Objects.new(name, "", true, message)
    end
  end

  def checkout(commit_hash)
    message = "Commit #{commit_hash} does not exist."
    if commits.include?(commit_hash)
      Objects.new(commit_hash, "", true, "HEAD is now at #{commit_hash}.")
    else Objects.new(commit_hash, "", false, message)
    end
  end
end



class Objects
  def initialize(name, object, state, message)
    @name = name
    @object = object
    @state = state
    @message = message
   end

  def message
    @message
  end

  def success?
    @state == true
  end

  def error?
    @state == false
  end

  def result
    @object
  end
end

class Commit
  attr_accessor :changes
  def initialize(message)
    @message = message
    @changes = {}
  end
end
