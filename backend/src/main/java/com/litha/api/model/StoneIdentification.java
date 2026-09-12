package com.litha.api.model;

import com.fasterxml.jackson.annotation.JsonIgnore;
import jakarta.persistence.*;
import java.time.Instant;

@Entity
public class StoneIdentification extends AuditedEntity {
    @ManyToOne(optional = false) @JsonIgnore public Stone stone;
    @Column(nullable = false) public String name;
    public String type;
    public Integer confidence;
    @Enumerated(EnumType.STRING) public IdentificationSource source;
    @Column(columnDefinition = "TEXT") public String notes;
    public Instant identifiedAt;
}
