package com.example.repository;

import com.example.model.Reservation;

import javax.persistence.EntityManager;
import java.util.List;

public class ReservationRepositoryImpl implements ReservationRepository {

    private EntityManager em;

    public ReservationRepositoryImpl(EntityManager em) {
        this.em = em;
    }

    @Override
    public Reservation findById(Long id) {
        return em.find(Reservation.class, id);
    }

    @Override
    public List<Reservation> findAll() {
        return em.createQuery("SELECT r FROM Reservation r", Reservation.class)
                .getResultList();
    }

    @Override
    public void save(Reservation reservation) {
        em.persist(reservation);
    }

    @Override
    public void delete(Reservation reservation) {
        em.remove(reservation);
    }
}