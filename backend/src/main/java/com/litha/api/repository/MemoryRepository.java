package com.litha.api.repository;
import com.litha.api.model.Memory; import org.springframework.data.jpa.repository.JpaRepository; import java.util.List;
public interface MemoryRepository extends JpaRepository<Memory, Long> { List<Memory> findByStoneId(Long stoneId); void deleteByStone_Id(Long stoneId); }
