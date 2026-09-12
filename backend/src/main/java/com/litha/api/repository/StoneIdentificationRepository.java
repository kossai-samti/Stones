package com.litha.api.repository;
import com.litha.api.model.StoneIdentification; import org.springframework.data.jpa.repository.JpaRepository; import java.util.List;
public interface StoneIdentificationRepository extends JpaRepository<StoneIdentification, Long> { List<StoneIdentification> findByStoneId(Long stoneId); }
