module time_corr_hist_container_class
use various_constants_class
use structure_class
use histogram_cutdown_class
use tic_toc_class

implicit none


  public :: clear_time_corr_hist_container
  public :: make_time_corr_hist_container 

  public :: print_g_d, print_g_s, print_einstein_diffuse_exp
  public :: print_h_s_hist, print_h_d_hist
    
  public :: check_if_time_corr_hist_container_is_allocated
  
  public :: get_time_corr_hist_r_max, get_time_corr_hist_r_bin, &
            get_time_corr_hist_n_time_bin, get_time_corr_hist_n_r_bin
  


  type time_corr_hist_container
    integer :: n_accum

    real(db) :: time_bin  ! otherwise time-binning not fully defined.
                          ! time bin not in the sense of MD time step
                          ! but time binning of G(r,t)
                          ! Defined fully when calculating context for this 
                          ! container

    ! dimensions are n_r_bin x n_t_bin
    type (histogram_cutdown), dimension(:), allocatable :: g_s_hists_sum
    type (histogram_cutdown), dimension(:), allocatable :: g_d_hists_sum    
    
    ! dimension is n_time   
    real(db), dimension(:), allocatable :: einstein_diffuse_exp
  
    ! dimension is n_r_bin. Store 1/(4*pi*r^2*dr).
    real(db), dimension(:), allocatable :: volume_prefac 
    
  end type time_corr_hist_container
  
  
  character(len=27), parameter, private :: filename_prefix1 = "output/einstein_diffuse_exp"  
  integer, private :: filname_number1 = 1  ! so first saved rdf file will be called einstein_diffuse_exp1.xml
  
  character(len=10), parameter, private :: filename_prefix2 = "output/g_s"  
  integer, private :: filname_number2 = 1  
  
  character(len=10), parameter, private :: filename_prefix3 = "output/g_d"  
  integer, private :: filname_number3 = 1      

contains

  subroutine check_if_time_corr_hist_container_is_allocated(container)
    type(time_corr_hist_container), intent(in) :: container
  
    if (allocated(container%einstein_diffuse_exp) == .false.) then
      write(*,*) " "
      write(*,*) "ERROR in time_corr_hist_container.f90"
      write(*,*) "Forgot to allocate time_corr_hist_container"
      stop
    end if  
  end subroutine check_if_time_corr_hist_container_is_allocated


  subroutine clear_time_corr_hist_container(container)
    type(time_corr_hist_container), intent(inout) :: container
    
    integer :: i
    
    call check_if_time_corr_hist_container_is_allocated(container)
     
    container%n_accum = 0
    container%einstein_diffuse_exp = 0.0
    
    do i = 1, size(container%g_s_hists_sum)
      container%g_s_hists_sum(i)%val = 0
      container%g_d_hists_sum(i)%val = 0
    end do 
    
  end subroutine clear_time_corr_hist_container
  
  
  ! notice time_bin determines the time binnning

  function make_time_corr_hist_container(r_max, r_bin, n_time_bin, time_bin) result(container)
    real(db), intent(in) :: r_max, r_bin, time_bin
    integer, intent(in) :: n_time_bin
    
    type (time_corr_hist_container) :: container
    integer :: n_r_bin, i
    real(db) :: temp, r_i
    
    container%n_accum = 0
    
    container%time_bin = time_bin 
    
    allocate(container%einstein_diffuse_exp(n_time_bin))
    
    allocate(container%g_s_hists_sum(n_time_bin))
    allocate(container%g_d_hists_sum(n_time_bin))
    
    do i = 1, n_time_bin
      container%g_s_hists_sum(i) = make_histogram_cutdown(r_max, r_bin)
      container%g_d_hists_sum(i) = make_histogram_cutdown(r_max, r_bin)
    end do
    
    
    n_r_bin = size(container%g_s_hists_sum(1)%val)
    
    
    allocate(container%volume_prefac(n_r_bin))
    
    
    ! cal volume element as (4*pi/3)*delta_r^3*(i^3 - (i-1)^3), where 
    ! i = 1, 2, ... n_r_bin
    
    temp = 3.0 / ( 4.0 * pi_value * r_bin**3 )
    
    do i = 1, n_r_bin
      !r_i = i - 0.5
      container%volume_prefac(i) = temp / ( i**3-(i-1)**3 )
    end do    
    
  end function make_time_corr_hist_container


  function get_time_corr_hist_n_time_bin(container) result(n_time_bin)
    type(time_corr_hist_container), intent(in) :: container
    integer :: n_time_bin
      
     call check_if_time_corr_hist_container_is_allocated(container) 
     
     n_time_bin = size(container%einstein_diffuse_exp)
  end function get_time_corr_hist_n_time_bin
  
  
  function get_time_corr_hist_r_bin(container) result(r_bin)
    type(time_corr_hist_container), intent(in) :: container
    real(db) :: r_bin  
    
    call check_if_time_corr_hist_container_is_allocated(container)     
    
    r_bin = container%g_s_hists_sum(1)%bin_length
  
  end function get_time_corr_hist_r_bin


  function get_time_corr_hist_r_max(container) result(r_max)
    type(time_corr_hist_container), intent(in) :: container
    real(db) :: r_max  
    
    integer n_r_bin
    real(db) :: r_bin
    
    call check_if_time_corr_hist_container_is_allocated(container)     
    
    r_bin = container%g_s_hists_sum(1)%bin_length
    n_r_bin = size(container%g_s_hists_sum(1)%val)
    
    r_max = r_bin * n_r_bin
  
  end function get_time_corr_hist_r_max
  
  
  function get_time_corr_hist_n_r_bin(container) result(n_r_bin)
    type(time_corr_hist_container), intent(in) :: container
    integer :: n_r_bin  
    
    call check_if_time_corr_hist_container_is_allocated(container)     

    n_r_bin = size(container%g_s_hists_sum(1)%val)
    
    !print *, "fiss3"
    !print *,  n_r_bin
  
  end function get_time_corr_hist_n_r_bin  


 ! The temperature is assumed to be in dimensionless units.

  subroutine print_einstein_diffuse_exp(container, n_atom, density, temperature)
    use flib_wxml
    type(time_corr_hist_container), intent(in) :: container
    integer, intent(in) :: n_atom
    real(db), optional, intent(in) :: temperature, density
    
    type (xmlf_t) :: xf
    integer :: i, n_eval_times
    character(len=50) :: filename
    
    if (filname_number1 < 10) then
      write(filename, '(i1)') filname_number1
    else if (filname_number1 < 100) then
      write(filename, '(i2)') filname_number1
    else if (filname_number1 < 1000) then
      write(filename, '(i3)') filname_number1
    else
      write(*,*) "ERROR: in save_rdf"
      write(*,*) "It is assumed that you did not intend to write"
      write(*,*) "to disk 1000 rdf xml files!!!!"
      stop
    end if
    
    filname_number1 = filname_number1 + 1
    
    filename = filename_prefix1 // trim(filename) // ".xml"
    
    write(*,'(3a)') "Write ", trim(filename), " to disk"
    
    n_eval_times = size(container%einstein_diffuse_exp)    
    
    call xml_OpenFile(filename, xf, indent=.true.)
    
    call xml_AddXMLDeclaration(xf, "UTF-8")
    call xml_NewElement(xf, "einstein-diffuse-exp")
    
    ! notice convert units of temperature from dimensionless to K  
    if (present(temperature) .and. present(density)) then
      call xml_AddAttribute(xf, "title", "T = " // trim(str(temperature * T_unit, format="(f10.5)")) // &
                                         " K: density = " // trim(str(density, format="(f10.5)")) &
                                         // " atoms/AA-3")
    else if (present(temperature)) then 
      call xml_AddAttribute(xf, "title", "T = " // str(temperature, format="(f10.5)") // &
                                         "K")
    else  if (present(density)) then 
      call xml_AddAttribute(xf, "title", "density = " // str(density, format="(f10.5)") &
                                         // "atoms/AA-3")
    end if
    
    call xml_AddAttribute(xf, "n-atom", str(n_atom, format="(i)"))
    call xml_AddAttribute(xf, "density", str(density, format="(f10.5)"))    
        
    call xml_AddAttribute(xf, "time-unit", "10^-13 s")
    call xml_AddAttribute(xf, "diffuse-units", "10^13 AA^2 s^-1")
    
    
    call xml_NewElement(xf, "this-file-was-created")
    call xml_AddAttribute(xf, "when", get_current_date_and_time())
    call xml_EndElement(xf, "this-file-was-created")
    
    do i = 1, n_eval_times
      call xml_NewElement(xf, "D-of-t")
      call xml_AddAttribute(xf, "t", str((i-1)*container%time_bin, format="(f10.5)"))
      call xml_AddAttribute(xf, "D", str(container%einstein_diffuse_exp(i), format="(f10.5)"))
      call xml_EndElement(xf, "D-of-t")
    end do 
    
    call xml_EndElement(xf, "einstein-diffuse-exp")
    
    call xml_Close(xf)    
  
  end subroutine print_einstein_diffuse_exp


  ! The temperature is assumed to be in dimensionless units.

  subroutine print_g_s(container, density, temperature)
    use flib_wxml
    type(time_corr_hist_container), intent(inout) :: container  ! inout because volume_prefac modified
    real(db), intent(in) :: density    
    real(db), optional, intent(in) :: temperature
    
    type (xmlf_t) :: xf
    integer :: i, n_eval_times, n_r_bin, i_bin
    real(db) :: r_bin
    character(len=50) :: filename
    
    if (filname_number2 < 10) then
      write(filename, '(i1)') filname_number2
    else if (filname_number2 < 100) then
      write(filename, '(i2)') filname_number2
    else if (filname_number2 < 1000) then
      write(filename, '(i3)') filname_number2
    else
      write(*,*) "ERROR: in print_g_s"
      write(*,*) "It is assumed that you did not intend to write"
      write(*,*) "to disk 1000 g_s xml files!!!!"
      stop
    end if
    
    filname_number2 = filname_number2 + 1
    
    filename = filename_prefix2 // trim(filename) // ".xml"  ! here filename is just a number on rhs
    
    write(*,'(3a)') "Write ", trim(filename), " to disk"
    
    
    n_eval_times = size(container%einstein_diffuse_exp)    
    n_r_bin = size(container%g_s_hists_sum(1)%val)
    r_bin = container%g_s_hists_sum(1)%bin_length
    
    call xml_OpenFile(filename, xf, indent=.true.)
    
    call xml_AddXMLDeclaration(xf, "UTF-8")
    call xml_NewElement(xf, "G_s-space-time-pair-correlation-function")
    
    ! notice convert units of temperature from dimensionless to K  
    if (present(temperature)) then
      call xml_AddAttribute(xf, "title", "T = " // trim(str(temperature * T_unit, format="(f10.5)")) // &
                                         " K: density = " // trim(str(density, format="(f10.5)")) &
                                         // " atoms/AA-3")
    else 
      call xml_AddAttribute(xf, "title", "density = " // str(density, format="(f10.5)") &
                                         // "atoms/AA-3")
    end if
    
    call xml_AddAttribute(xf, "bin-length", str(r_bin, format="(f10.5)"))
    
    call xml_AddAttribute(xf, "time-unit", "10^-13 s")
    call xml_AddAttribute(xf, "r-units", "AA")
    
    
    call xml_NewElement(xf, "this-file-was-created")
    call xml_AddAttribute(xf, "when", get_current_date_and_time())
    call xml_EndElement(xf, "this-file-was-created")
    
    ! Because of the way this prefactor is defined. This function prints out \tilde{q}^2
    ! See page 29 equation 30 in my notes.
    container%volume_prefac = container%volume_prefac / (container%n_accum*density)

    do i = 1, n_eval_times    
      do i_bin = 1, n_r_bin
        call xml_NewElement(xf, "G-s")
        call xml_AddAttribute(xf, "r", str((i_bin-0.5)*r_bin, format="(f10.5)"))
        call xml_AddAttribute(xf, "t", str((i-1)*container%time_bin, format="(f10.5)"))
        call xml_AddAttribute(xf, "G", str(container%g_s_hists_sum(i)%val(i_bin) * &
                              container%volume_prefac(i_bin), format="(f15.5)"))
        call xml_EndElement(xf, "G-s")
      end do 
    end do
    
    container%volume_prefac = container%volume_prefac * (container%n_accum*density)
    
    call xml_EndElement(xf, "G_s-space-time-pair-correlation-function")
    
    call xml_Close(xf)    
  
  end subroutine print_g_s


  ! The temperature is assumed to be in dimensionless units.
  !
  subroutine print_g_d(container, volume, n_atom, temperature)
    use flib_wxml
    type(time_corr_hist_container), intent(inout) :: container  ! inout because volume_prefac modified  
    real(db), intent(in) :: volume 
    real(db), optional, intent(in) :: temperature
    integer, optional, intent(in) :: n_atom
    
    type (xmlf_t) :: xf
    integer :: i, n_time_bin, n_r_bin, i_bin
    real(db) :: r_bin
    character(len=50) :: filename
    real(db) :: density
    
    density = n_atom / volume
    
    if (filname_number3 < 10) then
      write(filename, '(i1)') filname_number3
    else if (filname_number3 < 100) then
      write(filename, '(i2)') filname_number3
    else if (filname_number3 < 1000) then
      write(filename, '(i3)') filname_number3
    else
      write(*,*) "ERROR: in print_g_d"
      write(*,*) "It is assumed that you did not intend to write"
      write(*,*) "to disk 1000 g_d xml files!!!!"
      stop
    end if
    
    filname_number3 = filname_number3 + 1
    
    filename = filename_prefix3 // trim(filename) // ".xml"
    
    write(*,'(3a)') "Write ", trim(filename), " to disk"
    
    
    n_time_bin = size(container%einstein_diffuse_exp)    
    n_r_bin = size(container%g_s_hists_sum(1)%val)
    r_bin = container%g_s_hists_sum(1)%bin_length
    
    call xml_OpenFile(filename, xf, indent=.true.)
    
    call xml_AddXMLDeclaration(xf, "UTF-8")
    call xml_NewElement(xf, "G_d-space-time-pair-correlation-function")
    
    ! notice convert units of temperature from dimensionless to K  
    if (present(temperature)) then
      call xml_AddAttribute(xf, "title", "T = " // trim(str(temperature * T_unit, format="(f10.5)")) // &
                                         " K")
      call xml_AddAttribute(xf, "density", str(density, format="(f10.5)"))
      call xml_AddAttribute(xf, "density-unit", "atoms/AA-3")                                  
    else 
      call xml_AddAttribute(xf, "density", str(density, format="(f10.5)"))
      call xml_AddAttribute(xf, "density-unit", "atoms/AA-3")
                                         
    end if
    
    call xml_AddAttribute(xf, "n-atom", str(n_atom, format="(i)"))
    call xml_AddAttribute(xf, "time-bin", str(container%time_bin, format="(f10.5)"))
    call xml_AddAttribute(xf, "bin-length", str(r_bin, format="(f10.5)"))
    
    call xml_AddAttribute(xf, "n-time-bin", str(n_time_bin, format="(i)"))
    call xml_AddAttribute(xf, "n-r-bin", str(n_r_bin, format="(i)"))
    !call xml_AddAttribute(xf, "n-buffer_average-over", str(container%n_accum, format="(i)"))
    
    call xml_AddAttribute(xf, "time-unit", "10^-13 s")
    call xml_AddAttribute(xf, "r-units", "AA")
    
    
    call xml_NewElement(xf, "this-file-was-created")
    call xml_AddAttribute(xf, "when", get_current_date_and_time())
    call xml_EndElement(xf, "this-file-was-created")
    
    ! Because of the way this prefactor is defined. This function prints out \tilde{q}^2
    ! See page 29 equation 29 in my notes.
    container%volume_prefac = container%volume_prefac / (container%n_accum*density*(n_atom-1))

    do i = 1, n_time_bin    
      do i_bin = 1, n_r_bin
        call xml_NewElement(xf, "G-d")
        call xml_AddAttribute(xf, "r", str((i_bin-0.5)*r_bin, format="(f10.5)"))
        call xml_AddAttribute(xf, "t", str((i-1)*container%time_bin, format="(f10.5)"))
        call xml_AddAttribute(xf, "G", str(container%g_d_hists_sum(i)%val(i_bin) * &
                                           container%volume_prefac(i_bin), format="(f15.5)"))
        call xml_EndElement(xf, "G-d")
      end do 
    end do
    
    container%volume_prefac = container%volume_prefac * (container%n_accum*density*(n_atom-1))
    
    call xml_EndElement(xf, "G_d-space-time-pair-correlation-function")
    
    call xml_Close(xf)    
  
  end subroutine print_g_d  


  ! Printing out normalised version (i.e. divided by n_accum) of h_s

  subroutine print_h_s_hist(container, density, temperature)
    use flib_wxml
    type(time_corr_hist_container), intent(inout) :: container  ! inout because volume_prefac modified
    real(db), intent(in) :: density    
    real(db), optional, intent(in) :: temperature
    
    type (xmlf_t) :: xf
    integer :: i, n_eval_times, n_r_bin, i_bin
    real(db) :: r_bin
    character(len=50) :: filename
    
!    if (filname_number2 < 10) then
!      write(filename, '(i1)') filname_number2
!    else if (filname_number2 < 100) then
!      write(filename, '(i2)') filname_number2
!    else if (filname_number2 < 1000) then
!      write(filename, '(i3)') filname_number2
!    else
!      write(*,*) "ERROR: in save_rdf"
!      write(*,*) "It is assumed that you did not intend to write"
!      write(*,*) "to disk 1000 rdf xml files!!!!"
!      stop
!    end if
!    
!    filname_number2 = filname_number2 + 1
!    
!    filename = filename_prefix2 // trim(filename) // ".xml"  ! here filename is just a number on rhs
    
    filename = "output/h_s_histogram.xml"
    
    write(*,'(3a)') "Write ", trim(filename), " to disk"
    
    
    n_eval_times = size(container%einstein_diffuse_exp)    
    n_r_bin = size(container%g_s_hists_sum(1)%val)
    r_bin = container%g_s_hists_sum(1)%bin_length
    
    call xml_OpenFile(filename, xf, indent=.true.)
    
    call xml_AddXMLDeclaration(xf, "UTF-8")
    call xml_NewElement(xf, "normalised-h-s-histogram")
    
    ! notice convert units of temperature from dimensionless to K  
    if (present(temperature)) then
      call xml_AddAttribute(xf, "title", "T = " // trim(str(temperature * T_unit, format="(f10.5)")) // &
                                         " K: density = " // trim(str(density, format="(f10.5)")) &
                                         // " atoms/AA-3")
    else 
      call xml_AddAttribute(xf, "title", "density = " // str(density, format="(f10.5)") &
                                         // "atoms/AA-3")
    end if
    
    call xml_AddAttribute(xf, "bin-length", str(r_bin, format="(f10.5)"))
    
    call xml_AddAttribute(xf, "time-unit", "10^-13 s")
    call xml_AddAttribute(xf, "r-units", "AA")
    
    
    call xml_NewElement(xf, "this-file-was-created")
    call xml_AddAttribute(xf, "when", get_current_date_and_time())
    call xml_EndElement(xf, "this-file-was-created")
    

    do i = 1, n_eval_times    
      do i_bin = 1, n_r_bin
        call xml_NewElement(xf, "h-s")
        call xml_AddAttribute(xf, "r", str((i_bin-0.5)*r_bin, format="(f10.5)"))
        call xml_AddAttribute(xf, "t", str((i-1)*container%time_bin, format="(f10.5)"))
        call xml_AddAttribute(xf, "h", str(dble(container%g_s_hists_sum(i)%val(i_bin)) / &
                              dble(container%n_accum), format="(f15.5)"))
        call xml_EndElement(xf, "h-s")
      end do 
    end do
    
    call xml_EndElement(xf, "normalised-h-s-histogram")
    
    call xml_Close(xf)    
  
  end subroutine print_h_s_hist


  ! Printing out normalised version (i.e. divided by n_accum) of h_d 

  subroutine print_h_d_hist(container, density, temperature)
    use flib_wxml
    type(time_corr_hist_container), intent(inout) :: container  ! inout because volume_prefac modified
    real(db), intent(in) :: density    
    real(db), optional, intent(in) :: temperature
    
    type (xmlf_t) :: xf
    integer :: i, n_eval_times, n_r_bin, i_bin
    real(db) :: r_bin
    character(len=50) :: filename
    
!    if (filname_number2 < 10) then
!      write(filename, '(i1)') filname_number2
!    else if (filname_number2 < 100) then
!      write(filename, '(i2)') filname_number2
!    else if (filname_number2 < 1000) then
!      write(filename, '(i3)') filname_number2
!    else
!      write(*,*) "ERROR: in save_rdf"
!      write(*,*) "It is assumed that you did not intend to write"
!      write(*,*) "to disk 1000 rdf xml files!!!!"
!      stop
!    end if
!    
!    filname_number2 = filname_number2 + 1
!    
!    filename = filename_prefix2 // trim(filename) // ".xml"  ! here filename is just a number on rhs
    
    filename = "output/h_d_histogram.xml"
    
    write(*,'(3a)') "Write ", trim(filename), " to disk"
    
    
    n_eval_times = size(container%einstein_diffuse_exp)    
    n_r_bin = size(container%g_d_hists_sum(1)%val)
    r_bin = container%g_d_hists_sum(1)%bin_length
    
    call xml_OpenFile(filename, xf, indent=.true.)
    
    call xml_AddXMLDeclaration(xf, "UTF-8")
    call xml_NewElement(xf, "normalised-h-d-histogram")
    
    ! notice convert units of temperature from dimensionless to K  
    if (present(temperature)) then
      call xml_AddAttribute(xf, "title", "T = " // trim(str(temperature * T_unit, format="(f10.5)")) // &
                                         " K: density = " // trim(str(density, format="(f10.5)")) &
                                         // " atoms/AA-3")
    else 
      call xml_AddAttribute(xf, "title", "density = " // str(density, format="(f10.5)") &
                                         // "atoms/AA-3")
    end if
    
    call xml_AddAttribute(xf, "bin-length", str(r_bin, format="(f10.5)"))
    
    call xml_AddAttribute(xf, "time-unit", "10^-13 s")
    call xml_AddAttribute(xf, "r-units", "AA")
    
    
    call xml_NewElement(xf, "this-file-was-created")
    call xml_AddAttribute(xf, "when", get_current_date_and_time())
    call xml_EndElement(xf, "this-file-was-created")
    

    do i = 1, n_eval_times    
      do i_bin = 1, n_r_bin
        call xml_NewElement(xf, "h-d")
        call xml_AddAttribute(xf, "r", str((i_bin-0.5)*r_bin, format="(f10.5)"))
        call xml_AddAttribute(xf, "t", str((i-1)*container%time_bin, format="(f10.5)"))
        call xml_AddAttribute(xf, "h", str(dble(container%g_d_hists_sum(i)%val(i_bin)) / &
                              dble(container%n_accum), format="(f15.5)"))
        call xml_EndElement(xf, "h-d")
      end do 
    end do
    
    call xml_EndElement(xf, "normalised-h-d-histogram")
    
    call xml_Close(xf)    
  
  end subroutine print_h_d_hist

end module time_corr_hist_container_class