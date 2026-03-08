package com.example.service;

import com.example.model.Reservation;
import java.util.List;

public interface ReservationService {

    void createReservation(Reservation reservation);

    List<Reservation> getAllReservations();
}