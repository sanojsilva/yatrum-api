class TripsController < ApplicationController
  before_action :authenticate_request, only: [:create, :update, :destroy, :like]
  before_action :set_trip, only: [:show, :update, :destroy, :like]
  before_action :sanitise_params, only: [:create, :update]

  # GET /trips
  def index
    offset = ((params[:page] || 1).to_i - 1) * 6
    @trips =
      Trip
      .includes(:user, places: :pictures)
      .where.not(user_id: current_user.try(:id))
      .order(created_at: :desc)
      .limit(6)
      .offset(offset)

    total_pages = find_total_pages
    render json: {trips: cusotm_serializer(@trips, TripSerializer), total_pages: total_pages}
  end

  # GET /trips/1
  def show
    render json: @trip
  end

  # POST /trips
  def create
    @trip = current_user.trips.new(trip_params)
    if @trip.save
      render json: @trip, status: :created, location: @trip
    else
      render json: @trip.errors, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /trips/1
  def update
    if @trip.update(trip_params)
      # binding.pry
      render json: @trip
    else
      render json: @trip.errors, status: :unprocessable_entity
    end
  end

  # DELETE /trips/1
  def destroy
    @trip.destroy
  end
  
  # GET /users/:user_id/trips
  def get_user_trips
    user = User.find(params[:user_id])
    trips =
      user
      .trips
      .includes(places: :pictures)
      .order(created_at: :desc)
      .offset(params[:page])
      .limit(10)

    render json: trips
  end

  # POST /trips/search
  def search
    page = (params[:page] || 1).to_i - 1
    @trips =
      Trip
      .includes(:user, places: :pictures)
      .where.not(user_id: current_user.try(:id))
      .tagged_with(params[:keywords].try(:split), any: true)
      .order(created_at: :desc)
      .offset(page)
      .limit(10)
    
    render json: @trips
  end  

  # POST /trips/like
  def like
    @trip.toggle_like(current_user)
    render json: @trip
  end

  # GET /trips/trending
  def trending
    offset = ((params[:page] || 1).to_i - 1) * 6
    @trips =
      Trip
      .includes(:user, places: :pictures)
      .where.not(user_id: current_user.try(:id))
      .order(cached_weighted_average: :desc)
      .limit(6)
      .offset(offset)

    total_pages = find_total_pages
    render json: {trips: cusotm_serializer(@trips, TripSerializer), total_pages: total_pages}
  end
  
  private

  # find total pages in pagination
  def find_total_pages
    trips = Trip.all.count
    totol_pages = (trips/6).ceil 
  end

  # Use callbacks to share common setup or constraints between actions.
  def set_trip
    @trip = Trip.find(params[:id])
  end

  # Only allow a trusted parameter "white list" through.
  def trip_params
    params.require(:trip).permit(:id, :name, :description, :status, :start_date, :end_date, 
      places_attributes: [:id, :name, :description, :review, :visited_date, :_destroy,
        pictures_attributes: [:id, :description, :url, :public_id, :_destroy]
      ]
    )
  end

  def sanitise_params
    params['trip']['places_attributes'] = params['trip']['places']
      params['trip']['places_attributes'].each do |place|
      # Change for picture here
      place['pictures_attributes'] = place['pictures']
    end
  end

end
