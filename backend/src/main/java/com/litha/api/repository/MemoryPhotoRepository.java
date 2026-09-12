package com.litha.api.repository;
import com.litha.api.model.MemoryPhoto; import org.springframework.data.jpa.repository.JpaRepository; import java.util.List;
public interface MemoryPhotoRepository extends JpaRepository<MemoryPhoto, Long> { List<MemoryPhoto> findByMemoryIdOrderByDisplayOrder(Long memoryId); }
