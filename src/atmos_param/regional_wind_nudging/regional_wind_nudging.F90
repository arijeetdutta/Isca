!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!!                                                                   !!
!!                   GNU General Public License                      !!
!!                                                                   !!
!! This file is intended for use with ExeClim/Isca.                  !!
!!                                                                   !!
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

module regional_wind_nudging_mod

!-----------------------------------------------------------------------
! Regional relaxation of model winds toward prescribed u and v fields.
!
! Intended call position:
!   atmosphere.F90, after either idealized_moist_phys or hs_forcing
!   has calculated its tendencies, and before spectral_dynamics is called.
!
! Because this module adds to the common dt_ug and dt_vg arrays, it works
! with MiMA and other configurations using idealized_moist_model=.true.
!-----------------------------------------------------------------------

#ifdef INTERNAL_FILE_NML
use mpp_mod, only: input_nml_file
#else
use fms_mod, only: open_namelist_file
#endif

use fms_mod, only: error_mesg, FATAL, file_exist, check_nml_error, &
                   mpp_pe, mpp_root_pe, close_file, &
                   write_version_number, stdlog

use constants_mod, only: PI, SECONDS_PER_DAY
use time_manager_mod, only: time_type
use diag_manager_mod, only: register_diag_field, send_data

use interpolator_mod, only: interpolate_type, interpolator_init, &
                            interpolator, interpolator_end,       &
                            CONSTANT, INTERP_LINEAR_P

implicit none
private

public :: regional_wind_nudging_init
public :: regional_wind_nudging
public :: regional_wind_nudging_end

!-----------------------------------------------------------------------
! Namelist parameters
!-----------------------------------------------------------------------

logical :: do_regional_wind_nudging = .false.

! File basenames relative to the experiment INPUT directory.
! Do not include ".nc".
character(len=256) :: regional_u_wind_file = 'u_target'
character(len=256) :: regional_v_wind_file = 'v_target'

! Variable names inside the NetCDF files.
character(len=256) :: regional_u_wind_field = 'u_target'
character(len=256) :: regional_v_wind_field = 'v_target'

! Positive relaxation timescale in days.
real :: regional_wind_tau_days = 2.0

! Region boundaries. Longitude uses signed degrees in [-180,180).
real :: regional_lon_west  = -80.0
real :: regional_lon_east  =  20.0
real :: regional_lat_south =  20.0
real :: regional_lat_north =  80.0

! Width of the smooth horizontal transition in degrees.
real :: regional_taper_deg = 5.0

! Optional pressure range in Pa.
! Defaults encompass the full atmosphere.
real :: regional_p_top    = 0.0
real :: regional_p_bottom = 1.0e9

namelist /regional_wind_nudging_nml/                         &
    do_regional_wind_nudging,                                &
    regional_u_wind_file, regional_v_wind_file,              &
    regional_u_wind_field, regional_v_wind_field,            &
    regional_wind_tau_days,                                  &
    regional_lon_west, regional_lon_east,                    &
    regional_lat_south, regional_lat_north,                  &
    regional_taper_deg,                                      &
    regional_p_top, regional_p_bottom

!-----------------------------------------------------------------------
! Module data
!-----------------------------------------------------------------------

type(interpolate_type), save :: regional_u_interp
type(interpolate_type), save :: regional_v_interp

real :: regional_wind_rate = 0.0

integer :: id_udt_regional_nudge = -1
integer :: id_vdt_regional_nudge = -1

real, parameter :: missing_value = -1.e10

character(len=32), parameter :: mod_name = 'regional_wind_nudging'
character(len=128) :: version = '$Id: regional_wind_nudging.F90 $'
character(len=128) :: tagname = '$Name: $'

logical :: module_is_initialized = .false.

contains

!#######################################################################

subroutine regional_wind_nudging_init(axes, Time, lonb, latb)

!-----------------------------------------------------------------------
! Read the namelist, initialize the two target-field interpolators,
! and register separate diagnostics for the added momentum tendencies.
!-----------------------------------------------------------------------

integer, intent(in) :: axes(4)
type(time_type), intent(in) :: Time
real, intent(in), dimension(:,:) :: lonb, latb

integer :: unit, io, ierr
character(len=256), dimension(1) :: u_names, v_names

if (module_is_initialized) return

!-----------------------------------------------------------------------
! Read namelist
!-----------------------------------------------------------------------

#ifdef INTERNAL_FILE_NML
read(input_nml_file, nml=regional_wind_nudging_nml, iostat=io)
ierr = check_nml_error(io, 'regional_wind_nudging_nml')
#else
if (file_exist('input.nml')) then
    unit = open_namelist_file()
    ierr = 1

    do while (ierr /= 0)
        read(unit, nml=regional_wind_nudging_nml, iostat=io, end=10)
        ierr = check_nml_error(io, 'regional_wind_nudging_nml')
    enddo

10  call close_file(unit)
endif
#endif

call write_version_number(version, tagname)

if (mpp_pe() == mpp_root_pe()) then
    write(stdlog(), nml=regional_wind_nudging_nml)
endif

! Mark the module initialized even when forcing is disabled. This permits
! the driver to call this module unconditionally in every configuration.
module_is_initialized = .true.

if (.not. do_regional_wind_nudging) return

!-----------------------------------------------------------------------
! Validate namelist
!-----------------------------------------------------------------------

if (regional_wind_tau_days <= 0.0) then
    call error_mesg('regional_wind_nudging_init',               &
         'regional_wind_tau_days must be greater than zero',    &
         FATAL)
endif

if (regional_taper_deg <= 0.0) then
    call error_mesg('regional_wind_nudging_init',               &
         'regional_taper_deg must be greater than zero',        &
         FATAL)
endif

if (regional_lon_west >= regional_lon_east) then
    call error_mesg('regional_wind_nudging_init',               &
         'regional_lon_west must be less than regional_lon_east',&
         FATAL)
endif

if (regional_lat_south >= regional_lat_north) then
    call error_mesg('regional_wind_nudging_init',               &
         'regional_lat_south must be less than regional_lat_north',&
         FATAL)
endif

if (regional_p_top < 0.0 .or.                              &
    regional_p_bottom <= regional_p_top) then

    call error_mesg('regional_wind_nudging_init',               &
         'pressure limits must satisfy 0 <= p_top < p_bottom',   &
         FATAL)
endif

regional_wind_rate = 1.0 /                                 &
    (regional_wind_tau_days * SECONDS_PER_DAY)

!-----------------------------------------------------------------------
! Initialize interpolators
!-----------------------------------------------------------------------

u_names(1) = trim(regional_u_wind_field)
v_names(1) = trim(regional_v_wind_field)

call interpolator_init(                                      &
    regional_u_interp,                                       &
    trim(regional_u_wind_file)//'.nc',                       &
    lonb, latb,                                              &
    data_names=u_names,                                      &
    data_out_of_bounds=(/CONSTANT/),                         &
    vert_interp=(/INTERP_LINEAR_P/))

call interpolator_init(                                      &
    regional_v_interp,                                       &
    trim(regional_v_wind_file)//'.nc',                       &
    lonb, latb,                                              &
    data_names=v_names,                                      &
    data_out_of_bounds=(/CONSTANT/),                         &
    vert_interp=(/INTERP_LINEAR_P/))

!-----------------------------------------------------------------------
! Diagnostics
!-----------------------------------------------------------------------

id_udt_regional_nudge = register_diag_field(                 &
    mod_name,                                                &
    'udt_regional_nudge',                                    &
    axes(1:3),                                               &
    Time,                                                    &
    'zonal wind tendency from regional wind nudging',        &
    'm/s2',                                                  &
    missing_value=missing_value)

id_vdt_regional_nudge = register_diag_field(                 &
    mod_name,                                                &
    'vdt_regional_nudge',                                    &
    axes(1:3),                                               &
    Time,                                                    &
    'meridional wind tendency from regional wind nudging',   &
    'm/s2',                                                  &
    missing_value=missing_value)

end subroutine regional_wind_nudging_init

!#######################################################################

subroutine regional_wind_nudging(                            &
    Time, lon, lat, p_half, p_full, u, v, udt, vdt)

!-----------------------------------------------------------------------
! Add regional wind-nudging tendencies to the existing momentum
! tendencies supplied by MiMA's moist physics:
!
!   du/dt = W(lon,lat,p) * (u_target-u) / tau
!   dv/dt = W(lon,lat,p) * (v_target-v) / tau
!
! udt and vdt are INTENT(INOUT), so all existing MiMA tendencies remain.
!-----------------------------------------------------------------------

type(time_type), intent(in) :: Time

real, intent(in), dimension(:,:) :: lon, lat
real, intent(in), dimension(:,:,:) :: p_half, p_full
real, intent(in), dimension(:,:,:) :: u, v

real, intent(inout), dimension(:,:,:) :: udt, vdt

real, dimension(size(u,1),size(u,2),size(u,3)) :: u_nudge
real, dimension(size(v,1),size(v,2),size(v,3)) :: v_nudge

real, dimension(size(lon,1),size(lon,2)) :: lon_deg
real, dimension(size(lat,1),size(lat,2)) :: lat_deg
real, dimension(size(lon,1),size(lon,2)) :: lon_weight
real, dimension(size(lat,1),size(lat,2)) :: lat_weight
real, dimension(size(lon,1),size(lon,2)) :: horizontal_weight

integer :: k
logical :: used

if (.not. module_is_initialized) then
    call error_mesg('regional_wind_nudging',                  &
         'regional_wind_nudging_init has not been called',    &
         FATAL)
endif

if (.not. do_regional_wind_nudging) return

!-----------------------------------------------------------------------
! Interpolate the prescribed winds to the current model grid, pressure
! levels and model time.
!
! The timed interface also accepts static files: interpolator_mod
! automatically selects its no-time-axis path when necessary.
!-----------------------------------------------------------------------

call interpolator(                                           &
    regional_u_interp,                                       &
    Time,                                                    &
    p_half,                                                  &
    u_nudge,                                                 &
    trim(regional_u_wind_field))

call interpolator(                                           &
    regional_v_interp,                                       &
    Time,                                                    &
    p_half,                                                  &
    v_nudge,                                                 &
    trim(regional_v_wind_field))

!-----------------------------------------------------------------------
! Smooth North Atlantic mask
!-----------------------------------------------------------------------

lon_deg = modulo(lon * 180.0 / PI + 180.0, 360.0) - 180.0
lat_deg = lat * 180.0 / PI

lon_weight = 0.5 * (                                         &
    tanh((lon_deg-regional_lon_west)/regional_taper_deg) -   &
    tanh((lon_deg-regional_lon_east)/regional_taper_deg))

lat_weight = 0.5 * (                                         &
    tanh((lat_deg-regional_lat_south)/regional_taper_deg) -  &
    tanh((lat_deg-regional_lat_north)/regional_taper_deg))

horizontal_weight = max(0.0, min(1.0, lon_weight*lat_weight))

!-----------------------------------------------------------------------
! Convert target fields into tendencies.
!
! The optional pressure range is evaluated using model full-level
! pressure, in Pa. Outside the pressure range the tendency is zero.
!-----------------------------------------------------------------------

do k = 1, size(u,3)

    where (p_full(:,:,k) >= regional_p_top .and.              &
           p_full(:,:,k) <= regional_p_bottom)

        u_nudge(:,:,k) =                                      &
            horizontal_weight * regional_wind_rate *          &
            (u_nudge(:,:,k)-u(:,:,k))

        v_nudge(:,:,k) =                                      &
            horizontal_weight * regional_wind_rate *          &
            (v_nudge(:,:,k)-v(:,:,k))

    elsewhere

        u_nudge(:,:,k) = 0.0
        v_nudge(:,:,k) = 0.0

    endwhere

enddo

! Add to the tendencies already calculated by idealized_moist_phys.
udt = udt + u_nudge
vdt = vdt + v_nudge

if (id_udt_regional_nudge > 0) then
    used = send_data(id_udt_regional_nudge, u_nudge, Time)
endif

if (id_vdt_regional_nudge > 0) then
    used = send_data(id_vdt_regional_nudge, v_nudge, Time)
endif

end subroutine regional_wind_nudging

!#######################################################################

subroutine regional_wind_nudging_end

!-----------------------------------------------------------------------
! Release interpolator resources.
!-----------------------------------------------------------------------

if (.not. module_is_initialized) return

if (do_regional_wind_nudging) then
    call interpolator_end(regional_u_interp)
    call interpolator_end(regional_v_interp)
endif

module_is_initialized = .false.

end subroutine regional_wind_nudging_end

!#######################################################################

end module regional_wind_nudging_mod
