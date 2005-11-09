module lennard_jones_class
use various_constants_class
use structure_class
use variable_class
use near_neighb_class

implicit none

  type lj_pe_container
    type (variable), dimension(:), allocatable :: vars
  end type lj_pe_container


contains

  function lj_val_nn(str, container, nn_list) result (val)
    type (structure), intent(in) :: str
  	type (lj_pe_container), intent(in) :: container
    type (near_neighb_list), intent(in) :: nn_list
    real (db) :: val
  
    integer :: i1, i2, n_tot, j, i
    real (db) :: r_cut, rr_cut 
    real (db) :: sigma, epsilon, epsilon_times4
    real (db) :: rr, rri, rri3
  	real (db), dimension(ndim) :: diff_vec
    
    
  	sigma = container%vars(1)%val
  	epsilon = container%vars(2)%val
    epsilon_times4 = 4*epsilon
    
    r_cut = 2.0_db**(1.0_db / 6.0_db) * sigma
    rr_cut = r_cut * r_cut
    
  	n_tot = size(str%atoms)
    
    val = 0.0
    
    
    do j = 1, nn_list%n_pairs
    

    
  	  i1 = nn_list%pairs(2*j-1)
  	  i2 = nn_list%pairs(2*j)
      
      diff_vec = str%atoms(i1)%r - str%atoms(i2)%r
        
      do i = 1, ndim
        if (diff_vec(i) >= 0.5_db * str%box_edges(i)) then
          diff_vec(i) = diff_vec(i) - str%box_edges(i)
        end if
        if (diff_vec(i) < -0.5_db * str%box_edges(i)) then
          diff_vec(i) = diff_vec(i) + str%box_edges(i)
        end if       
      end do
        
      rr = sum(diff_vec*diff_vec)
        
      if (rr < rr_cut) then
        rri = sigma*sigma / rr
        rri3 = rri * rri * rri
        val = val + epsilon_times4 * rri3 * (rri3 - 1.0_db) + 1.0_db
        
        write (*, '(2i6, f12.6)') i1, i2, val
        stop
      end if
  
  	end do
 
 end function lj_val_nn


  function lj_val(str, container) result (val)
    type (structure), intent(in) :: str
		type (lj_pe_container), intent(in) :: container
    real (db) :: val
  
    integer :: i1, i2, n_tot, i
    real (db) :: r_cut, rr_cut 
    real (db) :: sigma, epsilon, epsilon_times4
    real (db) :: rr, rri, rri3
		real (db), dimension(ndim) :: diff_vec
    
    
		sigma = container%vars(1)%val
		epsilon = container%vars(2)%val
    epsilon_times4 = 4*epsilon
    
    r_cut = 2.0_db**(1.0_db / 6.0_db) * sigma
    rr_cut = r_cut * r_cut
    
		n_tot = size(str%atoms)
    
    val = 0.0
    
		do i1 = 1, n_tot
		  do i2 = i1+1, n_tot
        diff_vec = str%atoms(i1)%r - str%atoms(i2)%r
        
        do i = 1, ndim
          if (diff_vec(i) >= 0.5_db * str%box_edges(i)) then
            diff_vec(i) = diff_vec(i) - str%box_edges(i)
          end if
          if (diff_vec(i) < -0.5_db * str%box_edges(i)) then
            diff_vec(i) = diff_vec(i) + str%box_edges(i)
          end if       
        end do
        
        rr = sum(diff_vec*diff_vec)
        
        if (rr < rr_cut) then
          rri = sigma*sigma / rr
          rri3 = rri * rri * rri
          val = val + epsilon_times4 * rri3 * (rri3 - 1.0_db) + 1.0_db
          !write (*, '(2i6, f12.6)') i1, i2, val
        end if
			
			end do
		end do
      !stop  
  end function lj_val
  

  subroutine lj_deriv(str, deriv, container)
    type (structure), intent(in) :: str
    real (db), dimension(:,:), intent(out) :: deriv
		type (lj_pe_container), intent(in) :: container
  
    integer :: i1, i2, n_tot, i
    real (db) :: r_cut, rr_cut 
    real (db) :: sigma, epsilon, epsilon_times4
    real (db) :: rr, rri, rri3
		real (db), dimension(ndim) :: diff_vec
    real (db) :: prefac  ! used for calculating derivatives
    
    
		sigma = container%vars(1)%val
		epsilon = container%vars(2)%val
    epsilon_times4 = 4*epsilon
    
    r_cut = 2**0.166666666666667 * sigma
    rr_cut = r_cut * r_cut
    
		n_tot = size(str%atoms)
    
    deriv = 0.0
    
		do i1 = 1, n_tot
		  do i2 = i1+1, n_tot
        diff_vec = str%atoms(i1)%r - str%atoms(i2)%r
        
        do i = 1, ndim
          if (diff_vec(i) >= 0.5 * str%box_edges(i)) then
            diff_vec(i) = diff_vec(i) - str%box_edges(i)
          end if
          if (diff_vec(i) < -0.5 * str%box_edges(i)) then
            diff_vec(i) = diff_vec(i) + str%box_edges(i)
          end if       
        end do
        
        rr = sum(diff_vec*diff_vec)
        
        if (rr < rr_cut) then
          rri = sigma*sigma / rr
          rri3 = rri * rri * rri
          prefac = 48.0 * rri3 * (rri3 - 0.5) * rri
          deriv(i1,:) = deriv(i1,:) + prefac * diff_vec
          deriv(i2,:) = deriv(i2,:) - prefac * diff_vec
          
        end if
			
			end do
		end do
    
  end subroutine lj_deriv
  
    
end module lennard_jones_class
