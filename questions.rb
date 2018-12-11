require 'sqlite3'
require 'singleton'

class QuestionsDatabase < SQLite3::Database
  include Singleton
  def initialize
    super('questions.db')
    self.type_translation = true
    self.results_as_hash = true
  end
end

class Question
  def self.find_by_author_id(author_id)
    question = QuestionsDatabase.instance.execute(<<-SQL, author_id)
      SELECT
        *
      FROM
        questions
      WHERE
        user_id = ?
      SQL

      return nil if question.empty?

      question.map do |que|
        Question.new(que)
      end
  end

  def self.most_followed(n)
    Question_Follow.most_followed_questions(n)
  end

  def self.most_liked(n)
    QuestionLike.most_liked_questions(n)
  end

  attr_accessor :id, :title, :body, :user_id
  def initialize(options)
    @id = options['id']
    @title = options['title']
    @body = options['body']
    @user_id = options['user_id']    
  end  

  def author
    author = QuestionsDatabase.instance.execute(<<-SQL, self.user_id)
      SELECT
        *
      FROM
        users
      WHERE
        id = ?
      SQL

    return nil if author.empty?

    User.new(author.first)
  end

  def replies
    Reply.find_by_question_id(self.id)
  end

  def followers
    Question_Follow.followers_for_question_id(self.id)
  end

  def likers
    QuestionLike.likers_for_question_id(self.id)
  end

  def num_likes
    QuestionLike.num_likes_for_question_id(self.id)
  end  
end

class User
  def self.find_by_name(fname, lname)
    user = QuestionsDatabase.instance.execute(<<-SQL, fname, lname)
      SELECT
        *
      FROM
        users
      WHERE
        fname = ? AND lname = ?
      SQL

      return nil if user.empty?
    
    User.new(user.first)
  end
  
  attr_accessor :id, :fname, :lname
  def initialize(options)
    @id = options['id']
    @fname = options['fname']
    @lname = options['lname'] 
  end

  def authored_questions
    Question.find_by_author_id(self.id)
  end

  def authored_replies
    Reply.find_by_user_id(self.id)
  end

  def followed_questions
    Question_Follow.followed_questions_for_user_id(self.id)
  end

  def liked_questions
    QuestionLike.liked_questions_for_user_id(self.id)
  end

  def average_karma
    users = QuestionsDatabase.instance.execute(<<-SQL, self.id)
      SELECT
        COUNT(DISTINCT(questions.id)) AS total_questions_asked, COUNT(question_likes.user_id) AS total_likes, (CAST(total_questions_asked AS FLOAT) / total_likes) AS average_karma
      FROM
        questions
      LEFT OUTER JOIN
        question_likes
      ON
        questions.user_id = question_likes.user_id
      WHERE
        questions.user_id = ?
      
      SQL
  end
end

class Question_Follow
  def self.followers_for_question_id(question_id)
    users = QuestionsDatabase.instance.execute(<<-SQL, question_id)
      SELECT
        *
      FROM
        users
      JOIN
        question_follows
      ON 
        users.id = question_follows.user_id
      WHERE
        question_follows.question_id = ?
    SQL

    return nil if users.empty?
    users.map {|user| User.new(user) }    
  end

  def self.followed_questions_for_user_id(user_id)
    questions = QuestionsDatabase.instance.execute(<<-SQL, user_id)
      SELECT
        *
      FROM
        questions
      JOIN
        question_follows
      ON 
        questions.id = question_follows.question_id
      WHERE
        question_follows.user_id = ?
    SQL

    return nil if questions.empty?
    questions.map {|question| Question.new(question) }
  end

  def self.most_followed_questions(n)
    questions = QuestionsDatabase.instance.execute(<<-SQL, n)
    SELECT
        * , COUNT(question_follows.user_id) AS number_of_followers
      FROM
        questions
      JOIN
        question_follows
      ON 
        questions.id = question_follows.question_id
      GROUP BY
        questions.id
      ORDER BY
        COUNT(question_follows.user_id) DESC
      LIMIT ?
    SQL

    return nil if questions.empty?
    questions.map { |question| Question.new(question) }
  end

  attr_accessor :id, :user_id, :question_id
  def initialize(options)
    @id = options['id']
    @user_id = options['user_id']
    @question_id = options['question_id'] 
  end  
end

class Reply
  def self.find_by_user_id(user_id)
    reply = QuestionsDatabase.instance.execute(<<-SQL, user_id)
      SELECT
        *
      FROM
        replies
      WHERE
        user_id = ?
      SQL

    return nil if reply.empty?
    
    reply.map do |rep|
      Reply.new(rep)
    end
  end

  def self.find_by_question_id(question_id)
    replies = QuestionsDatabase.instance.execute(<<-SQL, question_id)
      SELECT
        *
      FROM
        replies
      WHERE
        question_id = ?
      SQL

      return nil if replies.empty?

      replies.map do |reply|
        Reply.new(reply)
      end
  end

  attr_accessor :id, :body, :question_id, :user_id, :parent_reply_id
  def initialize(options)
    @id = options['id']
    @body = options['body']
    @question_id = options['question_id']
    @user_id = options['user_id']    
    @parent_reply_id = options['parent_reply_id']
  end  

  def author
    author = QuestionsDatabase.instance.execute(<<-SQL, self.user_id)
      SELECT
        *
      FROM
        users
      WHERE
        id = ?
      SQL

    return nil if author.empty?

    User.new(author.first)
  end

  def question
    question = QuestionsDatabase.instance.execute(<<-SQL, self.question_id)
      SELECT
        *
      FROM
        questions
      WHERE
        id = ?
      SQL

    return nil if question.empty?

    Question.new(question.first)
  end

  def parent_reply
    parent_reply = QuestionsDatabase.instance.execute(<<-SQL, self.parent_reply_id)
      SELECT
        *
      FROM
        replies
      WHERE
        id = ?
      SQL

    return nil if parent_reply.empty?

    Reply.new(parent_reply.first)
  end

  def child_reply
    child_reply = QuestionsDatabase.instance.execute(<<-SQL, self.id)
      SELECT
        *
      FROM
        replies
      WHERE
        parent_reply_id = ?
      SQL

    return nil if child_reply.empty?

    Reply.new(child_reply.first)
  end
end

class QuestionLike

  def self.likers_for_question_id(question_id)
    likers = QuestionsDatabase.instance.execute(<<-SQL, question_id)
    SELECT
      users.id, users.fname, users.lname
    FROM
      users
    JOIN
      question_likes
    ON
      users.id = question_likes.user_id
    WHERE
      question_likes.question_id = ?
    SQL

    return nil if likers.empty?
    
    likers.map { |liker| User.new(liker) }
  end

  def self.num_likes_for_question_id(question_id)
    num_likers = QuestionsDatabase.instance.execute(<<-SQL, question_id)
    SELECT
      COUNT(users.id)
    FROM
      users
    JOIN
      question_likes
    ON
      users.id = question_likes.user_id
    WHERE
      question_likes.question_id = ?
    SQL

    num_likers.first.values.first
  end

  def self.liked_questions_for_user_id(user_id)
    questions = QuestionsDatabase.instance.execute(<<-SQL, user_id)
    SELECT
      *
    FROM
      questions
    JOIN
      question_likes
    ON
      questions.id = question_likes.question_id
    WHERE
      question_likes.user_id = ?
    SQL
  end


  def self.most_liked_questions(n)
    questions = QuestionsDatabase.instance.execute(<<-SQL, n)
    SELECT
        * , COUNT(question_likes.user_id) AS number_of_likes
      FROM
        questions
      JOIN
        question_likes
      ON 
        questions.id = question_likes.question_id
      GROUP BY
        questions.id
      ORDER BY
        COUNT(question_likes.user_id) DESC
      LIMIT ?
    SQL

    return nil if questions.empty?
    questions.map { |question| Question.new(question) }
  end

  attr_accessor :id, :user_id, :question_id
  def initialize(options)
    @id = options['id']
    @user_id = options['user_id']
    @question_id = options['question_id'] 
  end  
end