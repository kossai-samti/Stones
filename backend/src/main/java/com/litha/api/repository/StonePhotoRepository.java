package com.litha.api.repository;
import com.litha.api.model.StonePhoto; import org.springframework.data.jpa.repository.JpaRepository; import java.util.List;
public interface StonePhotoRepository extends JpaRepository<StonePhoto, Long> { List<StonePhoto> findByStone_IdOrderByDisplayOrder(Long stoneId); void deleteByStone_Id(Long stoneId); }
