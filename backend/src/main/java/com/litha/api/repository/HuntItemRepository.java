package com.litha.api.repository;
import com.litha.api.model.HuntItem; import org.springframework.data.jpa.repository.JpaRepository; import java.util.List;
public interface HuntItemRepository extends JpaRepository<HuntItem, Long> { List<HuntItem> findByStone_Id(Long stoneId); }
