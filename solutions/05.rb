require 'time'
require 'digest/sha1'

module ObjectStore
  class << self
    def init(&block)
      repository = Repository.new
      return repository unless block_given?
      repository.instance_eval(&block)
      repository
    end
  end

  class Value
    attr_accessor :message, :result

    def initialize(message, success: true, result: nil)
      @message = message
      @success = success
      @error = !success
      @result = result
    end

    def success?
      @success
    end

    def error?
      @error
    end
  end

  class Repository
    class Commit
      attr_accessor :commit_files, :hash, :message, :date
      TIME = "%a %b %d %H:%M %Y %z"

      def initialize(files, message)
        @hash = hash
        @commit_files = files
        @message = message
        @date = Time.new
      end

      def objects
        @commit_files.values
      end

      def to_s
        "Commit #{@hash}\nDate: #{date.strftime(TIME)}\n\n\t#{@message}"
      end
    end

    class Branch
      attr_accessor :added, :removed, :changed, :commits, :name
      TIME = "%a %b %d %H:%M %Y %z"

      def initialize(name, commits = [])
        @name = name
        @commits = commits
      end

      def remove_file(name)
        removed = @commits.last.commit_files[name]
        Value.new("Added #{name} for removal.", result: removed)
      end

      def new_commit(message, commit_files, changed_files)
        @commits << Commit.new(commit_files, message)
        hash = Digest::SHA1.hexdigest(@commits.last.date
                                    .strftime(TIME) + message)
        @commits.last.hash = hash
        Value.new("#{message}\n\t#{changed_files} objects changed",
                                                result: @commits.last)
      end

      def checkout(hash)
        index = @commits.index{ |x| x.hash == hash }
        if index.nil?
          Value.new("Commit #{hash} does not exist.", success: false)
        else
          @commits = @commits.take(index + 1)
          Value.new("HEAD is now at #{hash}.", result: @commits.last)
        end
      end
    end

    class Branches

      attr_reader :current, :branches
      def initialize
        @current = Branch.new("master")
        @branches = { "master": @current }
        @added = {}
        @removed = {}
        @changed = 0
      end

      def add(name, object)
        @changed += 1 unless @added.key?(name)
        @added[name] = object
        Value.new("Added #{name} to stage.", result: object)
      end

      def clean
        @added = {}
        @removed = []
        @changed = 0
      end

      def add_removed_changed(name)
        @removed.push(name)
        @changed += 1
      end

      def make_commits
        if @current.commits.empty?
          data = @added
        else
          data = @current.commits.last.commit_files.merge(@added)
        end
        data.delete_if{ |key, value| @removed.member?(key) }
      end

      def commit(message)
        if @changed == 0
          Value.new("Nothing to commit, working directory clean.",
                            success: false)
        else make_result(message)
        end
      end

      def make_result(message)
        result = @current.new_commit(message,
                                        make_commits,
                                        @changed)
        clean
        result
      end

      def remove_in_added_files(name)
         removed = @added.delete(name)
         add_removed_changed(name)
         Value.new("Added #{name} for removal.", result: removed)
      end

      def remove_in_branch(name)
        add_removed_changed(name)
        @current.remove_file(name)
      end

      def remove_file(name)
        has_commits = head.success?
        if has_commits and @current.commits.last.commit_files.
                                                      has_key?(name)
          remove_in_branch(name)
        else Value.new("Object #{name} is not committed.", success: false)
        end
      end

      def checkout_hash(hash)
        @current.checkout(hash)
      end

      def create(branch_name)
        if @branches.has_key?(branch_name.to_sym)
          Value.new("Branch #{branch_name} already exists.", success: false)
        else
          new_branch = Branch.new(branch_name, @current.commits.clone)
          @branches[branch_name.to_sym] = new_branch
          Value.new("Created branch #{branch_name}.", result: new_branch)
        end
      end

      def checkout(branch_name)
        if @branches.has_key?(branch_name.to_sym)
          @current = @branches[branch_name.to_sym]
          Value.new("Switched to branch #{branch_name}.",
                    result: @current)
        else
          Value.new("Branch #{branch_name} does not exist.", success: false)
        end
      end

      def remove(branch_name)
        if not @branches.has_key?(branch_name.to_sym)
          Value.new("Branch #{branch_name} does not exist.",
                     success: false)
        elsif @current.name.to_sym == branch_name.to_sym
          Value.new("Cannot remove current branch.", success: false)
        else
          Value.new("Removed branch #{branch_name}.",
                     result: @branches.delete(branch_name.to_sym))
        end
      end

      def list
        names = @branches.keys.map(&:to_s).sort
        result = names.reduce("") do |message, name|
          if name == @current.name
            message += "\n* " + name
          else
            message += "\n  " + name
          end
        end
        Value.new(result[1..-1])
      end

      def log
        if @current.commits.empty?
          Value.new("Branch #{@current.name} does not have any commits yet.",
                     success: false)
        else
          message = @current.commits.reverse.map(&:to_s).join("\n\n")
          Value.new(message.strip)
        end
      end

      def head
        if @current.commits.empty?
          Value.new("Branch #{@current.name} does not have any commits yet.",
                     success: false)
        else
          last_commit = @current.commits.last
          Value.new(last_commit.message, result: last_commit)
        end
      end

      def get(name)
        if @current.commits.empty? or
            not @current.commits.last.commit_files.key?(name)
          Value.new("Object #{name} is not committed.",
                                    success: false)
        else
          Value.new("Found object #{name}.",
                     result: @current.commits.last.commit_files[name])
        end
      end
    end

    attr_reader :branches
    def initialize
      @branches = Branches.new
    end

    def add(name, object)
      @branches.add(name, object)
    end

    def commit(message)
      @branches.commit(message)
    end

    def remove(name)
      @branches.remove_file(name)
    end

    def checkout(hash)
      @branches.checkout_hash(hash)
    end

    def branch
      @branches
    end

    def log
      @branches.log
    end

    def head
      @branches.head
    end

    def get(name)
      @branches.get(name)
    end
  end
end
