# author: maplgebra
# date: 2022-06-11 19:11:19
# Debugger for analyzing the layout of php memeory. 

define print_mm_heap
	print *alloc_globals.mm_heap
end

define ___zend_mm_constant
	set $zend_mm_chunk_size = 2 * 1024 * 1024
	set $zend_mm_page_size = 4 * 1024
end


define ___zend_mm_bin_pages
	set $bin_pages_list = (int [30]) {1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,5,3,1,1,5,3,2,2,5,3,7,4,5,3}
end

define ___zend_mm_bin_sizes
	set $bin_sizes_list = (int [30]) {8,16,24,32,40,48,56,64,80,96,112,128,160,192,224,256,320,384,448,512,640,768,896,1024,1280,1536,1792,2048,2560,3072}
end

define ___zend_mm_bin_elements
	set $bin_elements_list = (int [30]) {512,256,170,128,102,85,73,64,51,42,36,32,25,21,18,16,64,32,9,8,32,16,9,8,16,8,16,8,8,4}
end

define print_mm_page_info
	set $ptr = $arg0
	___zend_mm_constant
	set $page_offset = (((unsigned long)($ptr)) & (($zend_mm_chunk_size) - 1))
	set $page_num = (int)($page_offset / $zend_mm_page_size)
	set $chunk = (zend_mm_chunk*)(((unsigned long)($ptr)) & ~(($zend_mm_chunk_size) - 1))
	
	printf "[*]page_offset: 0x%x\n", $page_offset
	printf "[*]page_num: %d\n", $page_num
	printf "[*]chunk_adr: %p\n", $chunk
	
	set $is_first_page = 0	
	set $pi = $page_num
	set $are_small_pages = 0
	while $is_first_page == 0
		set $page_info = $chunk->map[$pi]

		if ($page_info & 0x80000000) && ($page_info & 0x40000000)
			#set $are_small_pages = 1
			printf "%d", $pi
		else
			if $page_info & 0x80000000
				set $is_first_page = 1
				set $first_page = ((char *)$chunk) + $pi * $zend_mm_page_size
				printf "[*]page_status: SRUN[first page of a bin used for \"small\" allocation]\n"
				set $bin_num = ((($page_info) & 0x0000001f) >> 0)
				printf "[*]bin_num: %d\n", $bin_num  
				___zend_mm_bin_sizes
				___zend_mm_bin_pages
				___zend_mm_bin_elements
				printf "[*]bin_size: 0x%x\n",  $bin_sizes_list[$bin_num]
				printf "[*]bin_elements: %d\n", $bin_elements_list[$bin_num]
				printf "[*]bin_pages: %d\n",  $bin_pages_list[$bin_num]
				if $bin_pages_list[$bin_num] > 1
					set $bpi = 0
					while $bpi < $bin_pages_list[$bin_num]
						printf "  -> page_%d_adr: %p\n", $bpi, $first_page + $bpi * $zend_mm_page_size
						set $bpi = $bpi + 1
					end
				end
				set $current_offset = $page_num - $pi
			else
				if $page_info & 0x40000000
					set $is_first_page = 1
					set $first_page = ((char *)$chunk) + $pi * $zend_mm_page_size
					printf "[*]page_status: LRUN[first page of \"large\" allocation]\n"
					set $lpage_count = ((($page_info) & 0x000003ff) >> 0)
					printf "[*]page_count: %d\n", $lpage_count
					set $lpi = 0
					while $lpi < $lpage_count
						printf "  -> page_%d_adr: %p\n", $lpi, $first_page + $zend_mm_page_size * $lpi
						set $lpi = $lpi + 1
					end
					set $current_offset = $page_num - $pi 
				end
			end
		end

		#if $page_info == 0
		#	set $is_first_page = 1
		#	set $fist_page = 
		#	printf "page_status: FRUN[free page]\n"
		#end

		set $pi = $pi - 1
	end

	printf "[*]current_local_page_offset: %d\n", $current_offset	
end


define print_mm_main_chunk_info 
	if $argc == 1
		set $page_range = 8
	else
		set $page_range = $arg1
	end

	___zend_mm_constant
	___zend_mm_bin_sizes
	___zend_mm_bin_pages
	___zend_mm_bin_elements
	
	set $start_num  = $arg0
	set $main_chunk = (zend_mm_chunk*)alloc_globals.mm_heap->main_chunk
	set $start_page = $start_num * $zend_mm_page_size


	set $pi = 0
	set $lp = 1
	set $current_page_offset = $start_num + $pi
	set $current_page_adr = ((char *)$main_chunk) + $current_page_offset * $zend_mm_page_size 
	while $pi < $page_range
		set $page_info = $main_chunk->map[$current_page_offset]
		if $lp > 1
			printf "  ->"
			set $lp = $lp - 1
		end

		if ($page_info & 0x80000000) && ($page_info & 0x40000000)
			printf "  ->"
		end

		printf "[-]page_%d_adr (%p): " ,$current_page_offset ,$current_page_adr
		
		if ($page_info & 0x80000000) && ($page_info & 0x40000000)
			printf "[SMALL], [N%d], [0x%x]", ((($page_info) & 0x01ff0000) >> 16), $bin_sizes_list[((($page_info) & 0x0000001f) >> 0)]
		else
			if $page_info & 0x80000000
				printf "[SRUN], [0x%x]", $bin_sizes_list[((($page_info) & 0x0000001f) >> 0)]
			end

			if $page_info & 0x40000000
				set $lp = ((($page_info) & 0x000003ff) >> 0)
				printf "[LRUN], [P%d], ", $lp
			end

			if $lp > 1
				printf "[USED], [LARGE]"
			else 
				if $page_info == 0
					printf "[MAY_FRUN], [MAY_USED_FOR_LARGE]"
				end	
			end
		end	
		
		printf "\n"
		set $current_page_adr = $current_page_adr + $zend_mm_page_size
		set $pi = $pi + 1
		set $current_page_offset = $start_num + $pi
	end	
end