package com.litha.api.model;

import jakarta.persistence.*;
import java.time.LocalDate;

@Entity
public class Stone extends AuditedEntity {
    @Column(nullable = false) public String name;
    @Column(columnDefinition = "TEXT") public String description;
    @Column(columnDefinition = "TEXT") public String whyKept;
    @Enumerated(EnumType.STRING) public AcquisitionType acquisitionType;
    public LocalDate acquiredAt;
    @ManyToOne public Location location;
    @Column(nullable = false) public boolean favorite;
    /** 1 = like, 5 = love. Kept separate from a hunt item's wanted rating. */
    public Integer rating;
}
