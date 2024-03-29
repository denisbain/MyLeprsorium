require 'rubygems'
require 'sinatra'
require 'sinatra/reloader'
require 'sqlite3'

def init_db
  @db = SQLite3::Database.new 'leprosorium2.db'
  @db.results_as_hash = true
end

configure do
  init_db
  @db.execute 'CREATE TABLE IF NOT EXISTS Posts
                  (
                      id            INTEGER PRIMARY KEY AUTOINCREMENT,
                      author        TEXT,
                      created_date  TEXT,
                      content       TEXT
                  )'
  @db.execute 'CREATE TABLE IF NOT EXISTS Comments
                  (
                      id            INTEGER PRIMARY KEY AUTOINCREMENT,
                      comment       TEXT
                  )'
  enable :sessions
end

helpers do
  def username
    session[:identity] ? session[:identity] : 'Hello stranger'
  end
end

before '/secure/*' do
  init_db
  unless session[:identity]
    session[:previous_url] = request.path
    @error = 'Sorry, you need to be logged in to visit ' + request.path
    halt erb(:login_form)
  end
end

get '/' do
  erb 'Can you handle a <a href="/secure/place">secret</a>?'
end

get '/login/form' do
  erb :login_form
end

post '/login/attempt' do
  session[:identity] = params['username']
  where_user_came_from = session[:previous_url] || '/'
  redirect to where_user_came_from
end

get '/logout' do
  session.delete(:identity)
  erb "<div class='alert alert-message'>Logged out</div>"
end

get '/secure/place' do
  erb 'This is a secret place that only <%=session[:identity]%> has access to!'
end

get '/new' do
  erb :new
end

post '/new' do
  init_db
  content = params[:content]
  author = params[:author]

  @db.execute 'INSERT INTO Posts (author, content, created_date) VALUES (?, ?, datetime())', [author, content]

  redirect to '/index'
end

get '/index' do
  init_db

  @results = @db.execute 'SELECT * FROM Posts ORDER BY id DESC'

  erb :index
end

get '/index/:post_id' do
  init_db
  post_id = params[:post_id]

  results = @db.execute 'SELECT * FROM Posts where id = ?', [post_id]
  @row = results[0]

  @comments = @db.execute'SELECT * FROM Comments WHERE id = ?', [post_id]

  erb :details
end

post '/index/:post_id' do
  init_db
  comment = params[:comment]
  post_id = params[:post_id]

  @db.execute 'INSERT INTO Comments (comment) VALUES (?)', [comment]

  redirect to('/index/' + post_id)
end