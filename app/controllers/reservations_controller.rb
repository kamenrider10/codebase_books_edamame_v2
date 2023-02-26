class ReservationsController < ApplicationController
  before_action :redirect_to_sign_in, only: %i[index show], unless: :user_signed_in?
  before_action :delete_old_reservations, only: %i[show]

  def index
    @reservations = Reservation.where(user_id: current_user&.id).where("reservation_at >= ?",
                                                                       Time.now).order(reservation_at: :asc)
  end

  def show
    @reservation = Reservation.find(params[:id])
    redirect_to book_path(@reservation.book) unless @reservation
  end

  def create
    @user = current_user
    @reservation = Book.find(params[:book_id]).reservations.build(reservation_param(params))
    # return unless @reservation.save
    if @reservation.save
      UserMailer.with(user: @user).reservation_at.deliver_later
      flash[:success] = "予約が完了しました"
      redirect_to reservations_path
    end
    # flash[:success] = "予約が完了しました"
    # redirect_to reservations_path
  end

  def destroy
    reservation = Reservation.find(params[:id])
    if reservation.destroy
      flash[:success] = "予約のキャンセルが完了しました"
      redirect_to reservations_path
    else
      redirect_to request.referer
    end
  end

  def reservation_param(data)
    @reservation_info = { book_id: data[:book_id],
                          user_id: current_user&.id,
                          reservation_at: data[:start_at],
                          return_at: data[:return_at] }
  end

  def delete_old_reservations
    old_reservations = Reservation.where("reservation_at < ?", Date.today)
    if old_reservations.destroy_all && old_reservations.exists?
      redirect_to reservations_path
    end
  end
end
