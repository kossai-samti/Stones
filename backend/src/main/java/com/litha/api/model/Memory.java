package com.litha.api.model;

import com.fasterxml.jackson.annotation.JsonProperty;
import jakarta.persistence.*;
import java.time.LocalDate;

@Entity @Table(name = "memories")
public class Memory extends AuditedEntity {
    @ManyToOne(optional = false)
    @JsonProperty(access = JsonProperty.Access.WRITE_ONLY)
    public Stone stone;
    @Column(nullable = false) public String title;
    @Column(columnDefinition = "TEXT") public String content;
    public LocalDate occurredAt;
    @ManyToOne public Location location;
}
