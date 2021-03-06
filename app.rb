# app.rb
require 'json'
require 'sinatra'
require 'sinatra/activerecord'
require 'sinatra/config_file'

require_relative './models.rb'

ROOT_DIR = File.dirname(__FILE__)
CONFIG_PATH = ROOT_DIR + '/config/config.yml'
config_file CONFIG_PATH

set :show_exceptions, :after_handler
set :public_folder, 'frontend/dist'

error ActiveRecord::RecordNotFound do
  404
end

before do
  header_name = settings.access['category-header']
  category = settings.access['category']
  if category.kind_of?(Array) && !category.empty?
    halt 403 unless request.env.key?(header_name) && category.include?(request.env[header_name])
  end
end

get '/' do
  send_file 'frontend/dist/index.html'
end

get '/floorsection/?' do
  FloorSection.order(:floor, :name).to_json
end

get '/floorsection/:id/?' do |id|
  FloorSection.find(id).to_json
end

get '/floorsection/:id/shelfrows/?' do |id|
  FloorSection.find(id).shelf_rows.order(:name).to_json
end

get '/floorsection/:id/shelfrows/enabled/?' do |id|
  FloorSection.find(id).shelf_rows.where(enabled: true).order(:name).to_json
end

get '/floorsection/:id/shelfrows/disabled/?' do |id|
  FloorSection.find(id).shelf_rows.where(enabled: false).order(:name).to_json
end

get '/shelfrow/:id/enable/?' do |id|
  sr = ShelfRow.find(id)
  sr.enabled = true
  sr.save
  id
end

get '/shelfrow/:id/disable/?' do |id|
  sr = ShelfRow.find(id)
  sr.enabled = false
  sr.save
  id
end

get '/signature/?' do
  query = []
  query_params = {}
  if params[:from_year]
    query_params[:year_max] = params[:from_year].to_i
    query.push('year_max >= :year_max')
  end
  if params[:to_year]
    query_params[:year_min] = params[:to_year].to_i
    query.push('year_min <= :year_min')
  end
  if params[:sig_num_min]
    query_params[:sig_num_min] = params[:sig_num_min].to_i
    query.push('signature_number >= :sig_num_min')
  end
  if params[:sig_num_max]
    query_params[:sig_num_max] = params[:sig_num_max].to_i
    query.push('signature_number <= :sig_num_max')
  end
  if params[:sig_pref]
    query_params[:sig_pref] = params[:sig_pref]
    # query_params[:sig_pref] = '%#{params[:sig_pref]}%'
    query.push('signature_prefix = :sig_pref')
  end
  # p query.join(' and '), query_params
  Signature.where(query.join(' and '), query_params)
           .order(:signature_prefix, :signature_number, :signature)
           .to_json
  # sql = Signature.where(query.join(' and '), query_params).to_sql
  # ActiveRecord::Base.connection.exec_query(sql).to_json
  # [].to_json
  # Signature.all.to_json
end

get '/signature/prefixes/?' do
  Signature.select(:signature_prefix)
           .distinct
           .order(:signature_prefix)
           .map(&:signature_prefix)
           .to_json
end

get '/signature/:id/?' do |id|
  Signature.find(id).to_json
end

get '/simulation/?' do
  Simulation.select(:id, :name, :volume_width).to_json
end

put '/simulation/?' do
  data = JSON.parse(request.body.read)
  keys = ['shelfs', 'books', 'name', 'volume_width', 'description']
  keys.each { |k| halt 403, 'Unable to find ' + k unless data.key?(k) }
  s = Simulation.new
  keys.each { |k| s.send(k + '=', data[k]) }
  s.save
  s.id
end

options '/simulation/?' do
  ''
end

get '/simulation/:id/?' do |id|
  Simulation.find(id).to_json
end

delete '/simulation/:id/?' do |id|
  Simulation.delete(id)
  200
end

post '/simulation/:id/?' do |id|
  data = JSON.parse(request.body.read)
  keys = ['shelfs', 'books', 'name', 'volume_width', 'description']
  keys.each { |k| halt 403, 'Unable to find ' + k unless data.key?(k) }
  s = Simulation.find(id)
  keys.each { |k| s.send(k + '=', data[k]) }
  s.save
  id
end

options '/simulation/:id/?' do |id|
  ''
end
