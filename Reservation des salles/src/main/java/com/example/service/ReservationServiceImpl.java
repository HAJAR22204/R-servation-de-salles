package com.example.service;

import com.example.model.Reservation;
import com.example.repository.ReservationRepository;

import javax.persistence.EntityManager;
import java.util.List;

public class ReservationServiceImpl implements ReservationService {

    private EntityManager em;
    private ReservationRepository reservationRepository;

    public ReservationServiceImpl(EntityManager em, ReservationRepository reservationRepository) {
        this.em = em;
        this.reservationRepository = reservationRepository;
    }

    @Override
    public void createReservation(Reservation reservation) {
        em.getTransaction().begin();
        reservationRepository.save(reservation);
        em.getTransaction().commit();
    }

    @Override
    public List<Reservation> getAllReservations() {
        return reservationRepository.findAll();
    }
}