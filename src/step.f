c
c step.f
c 11/10/95
c
c This program solves 2-D Stokes or Navier-Stokes equation for Poiseuille flow
c with a symmetrical constriction, using the projection time-stepping method
c to deal with pressure. The eqn is discretized by Finite Volume Method
c
c The convection term is modelled using central differencing, upwinding or
c the QUICK scheme.
c
c ================================================================   
c
      MODULE Global_Var   ! For global variables and constants
         IMPLICIT NONE
         CHARACTER (LEN=80) :: Uout,Vout,Pout,PsiOut,
     $        DivOut,SepPsiMax,Wvort,CheckIn,CheckOut
         INTEGER :: m,n,i,j,k,no_space,INFO
         INTEGER :: X,Y,gamma,maxstep,iinfo,method
         DOUBLE PRECISION :: dx,dy,dt,eps,Xm,h,nu,Re
         INTEGER, ALLOCATABLE, SAVE :: IPIV(:)
         DOUBLE PRECISION, ALLOCATABLE, SAVE :: u_star(:,:),v_star(:,:),
     $u_n(:,:),v_n(:,:),u_n_plus_1(:,:),v_n_plus_1(:,:),A(:,:),p(:),
     $S(:),UPP(:,:),VTT(:,:),WORK(:),psi(:,:),div(:,:)
      END MODULE Global_Var 


c
c =================================================================
c
      SUBROUTINE Input_Data
         USE Global_Var
         INTEGER :: ilin,len
         CHARACTER :: line*80,junk*80
         CHARACTER(LEN=80) :: fname
         LOGICAL :: exists
         INTEGER, PARAMETER :: ichan=100
c
c Initial default values
        method=0
        Xm=1.0
        h=1.0
        gamma=2
        nu=1.0
        dt=1.0
        eps=1.0
        X=10
        Y=10
        maxstep=1
        iinfo=1
        Uout="step-u.dat"
        Vout="step-v.dat"
        Pout="step-p.dat"
        PsiOut="step-psi.dat"
        DivOut="step-div.dat"
        SepPsiMax="Separation.PsiMax"
        Wvort="Wall.vorticity"
        CheckIn=""
        CheckOut=""
c
        fname = 'step.dat'
        INQUIRE(FILE=fname, EXIST=exists)
        IF (.NOT. exists) THEN
           fname = 'input/step.dat'
           INQUIRE(FILE=fname, EXIST=exists)
        END IF
        IF (.NOT. exists) THEN
           WRITE(*,*) 'ERROR: Could not find input file step.dat'
           STOP
        END IF

        OPEN(ichan,FILE=fname,STATUS="OLD",ERR=100)
c
        ilin=0
        DO
          ilin=ilin+1
          READ(ichan,"(A)",ERR=200,END=300)line
            line=ADJUSTL(line)
            len=LEN_TRIM(line)
          IF(len.EQ.0)THEN
            CONTINUE
          ELSE IF(line(1:1).EQ."%".OR.line(1:1).EQ."!")THEN
            CONTINUE
          ELSE IF(line(1:1).EQ.";".OR.line(1:1).EQ."#")THEN
            CONTINUE
          ELSE IF(line(1:7).EQ."METHOD ")THEN
            READ(line,10010,ERR=200)junk(1:7),method
          ELSE IF(line(1:3).EQ."XM ")THEN
            READ(line,10020,ERR=200)junk(1:3),Xm
          ELSE IF(line(1:2).EQ."H ")THEN
            READ(line,10020,ERR=200)junk(1:2),h
          ELSE IF(line(1:6).EQ."GAMMA ")THEN
            READ(line,10010,ERR=200)junk(1:6),gamma
          ELSE IF(line(1:3).EQ."NU ")THEN
            READ(line,10020,ERR=200)junk(1:3),nu
          ELSE IF(line(1:3).EQ."DT ")THEN
            READ(line,10020,ERR=200)junk(1:3),dt
          ELSE IF(line(1:4).EQ."EPS ")THEN
            READ(line,10020,ERR=200)junk(1:4),eps
          ELSE IF(line(1:3).EQ."RE ")THEN
            READ(line,10020,ERR=200)junk(1:3),Re
          ELSE IF(line(1:2).EQ."X ")THEN
            READ(line,10010,ERR=200)junk(1:2),X
          ELSE IF(line(1:2).EQ."Y ")THEN
            READ(line,10010,ERR=200)junk(1:2),Y
          ELSE IF(line(1:8).EQ."MAXSTEP ")THEN
            READ(line,10010,ERR=200)junk(1:8),maxstep
          ELSE IF(line(1:6).EQ."IINFO ")THEN
            READ(line,10010,ERR=200)junk(1:6),iinfo
          ELSE IF(LINE(1:8).EQ."CHECKIN ")THEN
            READ(line,10030,ERR=200)junk(1:8),CheckIn
          ELSE IF(LINE(1:9).EQ."CHECKOUT ")THEN
            READ(line,10030,ERR=200)junk(1:9),CheckOut
          ELSE IF(LINE(1:5).EQ."UOUT ")THEN
            READ(line,10030,ERR=200)junk(1:5),Uout
          ELSE IF(LINE(1:5).EQ."VOUT ")THEN
            READ(line,10030,ERR=200)junk(1:5),Vout
          ELSE IF(LINE(1:5).EQ."POUT ")THEN
            READ(line,10030,ERR=200)junk(1:5),Pout
          ELSE IF(LINE(1:7).EQ."PSIOUT ")THEN
            READ(line,10030,ERR=200)junk(1:7),PsiOut
          ELSE IF(LINE(1:7).EQ."DIVOUT ")THEN
            READ(line,10030,ERR=200)junk(1:7),DivOut
          ELSE IF(LINE(1:10).EQ."SEPPSIMAX ")THEN
            READ(line,10030,ERR=200)junk(1:10),SepPsiMax
          ELSE IF(LINE(1:6).EQ."WVORT ")THEN
            READ(line,10030,ERR=200)junk(1:6),Wvort
          ELSE
            WRITE(*,*)
     &         "ERROR: Unknown option in "//fname//" on line",ILIN
            WRITE(*,*)"ERROR: Contents of line:"
            WRITE(*,"(A)")line(1:len)
            WRITE(*,*)
            STOP
          ENDIF
        ENDDO
        GOTO 300
c
  100   WRITE(*,*)
     &    "ERROR: Error on opening ",fname
        WRITE(*,*)
        STOP
c
  200   WRITE(*,*)
     &    "ERROR: Error on read from ",fname," on line",ILIN
        WRITE(*,*)"ERROR: Contents of line:"
        WRITE(*,"(A)")line(1:len)
c        WRITE(*,*)IOS
        STOP
c
  300   CONTINUE
c
        CLOSE(ichan)
c
        dx=2.0*Xm/X
        dy=h/Y
c
c Perform some basic semantic checking
        if(MOD(X,2).NE.0)THEN
          WRITE(*,*)"ERROR: X must be divisible by 2"
          STOP
        endif
        if(MOD(Y,gamma).NE.0)THEN
          WRITE(*,*)"ERROR: Y must be divisible by gamma"
          STOP
        endif
c
10010   FORMAT(A,I40)
10020   FORMAT(A,F40.0)
10030   FORMAT(A,A40)
C
       END SUBROUTINE Input_Data
c
c ===============================================================
c
      SUBROUTINE Alloc_Arrays
         USE Global_Var
         ALLOCATE(u_star(X+1,Y+1),v_star(X+1,Y+1),
     $      u_n(X+1,Y+1),v_n(X+1,Y+1),
     $      u_n_plus_1(X+1,Y+1),v_n_plus_1(X+1,Y+1),
     $      psi(X+1,Y+1),div(X+1,Y+1),
     $      A(Y*X/2+X/2*Y/gamma,Y*X/2+X/2*Y/gamma),
     $      p(Y*X/2+X/2*Y/gamma),IPIV(Y*X/2+X/2*Y/gamma),
c     $      S(Y*X/2+X/2*Y/gamma),
c     $      UPP(Y*X/2+X/2*Y/gamma,Y*X/2+X/2*Y/gamma),
c     $      VTT(Y*X/2+X/2*Y/gamma,Y*X/2+X/2*Y/gamma),
c     $      WORK(5*(Y*X/2+X/2*Y/gamma)-4),
     $        STAT=no_space)
         IF (no_space /= 0) THEN
            PRINT *,"Insufficient Space for arrays"
            STOP
         ENDIF
      END SUBROUTINE Alloc_Arrays
c
c ===============================================================
c
      SUBROUTINE Matrix
        USE Global_Var 
c
        A=0.0       ! to set all entries in A to zero
c
        j=Y                             !
        DO i=2,X/2-1                    !
           k=(j-1)*X/2+i                !
           A(k,k-X/2)=dx**2             !
           A(k,k-1)=dy**2               ! Top (x<0) boundary cells
           A(k,k)=-(dx**2+2.0*dy**2)    ! 
           A(k,k+1)=dy**2               !
        ENDDO                           !
c
        j=1                             !
        DO i=2,X/2-1                    !
           k=(j-1)*X/2+i                !
           A(k,k-1)=dy**2               ! Bottom (x<0) boundary cells
           A(k,k)=-(dx**2+2.0*dy**2)    ! 
           A(k,k+1)=dy**2               !
           A(k,k+X/2)=dx**2             !
        ENDDO                           !
c
        i=1                             !
        DO j=2,Y-1                      !
           k=(j-1)*X/2+i                !
           A(k,k-X/2)=dx**2             !
           A(k,k)=-(2.0*dx**2+dy**2)    ! Left (vertical) boundary cells
           A(k,k+1)=dy**2               !
           A(k,k+X/2)=dx**2             !
        ENDDO                           !
c
        i=X/2                           !
        DO j=Y/gamma+1,Y-1              !
           k=(j-1)*X/2+i                !
           A(k,k-X/2)=dx**2             !
           A(k,k-1)=dy**2               ! step (vertical) boundary cells
           A(k,k)=-(2.0*dx**2+dy**2)    !
           A(k,k+X/2)=dx**2             !
        ENDDO                           !
c
        i=1                         !
        j=Y                         !
        k=(j-1)*X/2+i               !
        A(k,k-X/2)=dx**2            ! Top left corner cell
        A(k,k)=-(dx**2+dy**2)       !
        A(k,k+1)=dy**2              !
c
       A(1,1)=1.0        ! to set ambient level of pressure
c
c        i=1                          !
c        j=1                          !
c        k=(j-1)*X/2+i                !
c        A(k,k)=-(dx**2+dy**2)        ! Bottom left corner cell
c        A(k,k+1)=dy**2               !
c        A(k,k+X/2)=dx**2             !
c
        i=X/2                         !
        j=Y                           !
        k=(j-1)*X/2+i                 !
        A(k,k-X/2)=dx**2              ! Step corner cell
        A(k,k-1)=dy**2                !
        A(k,k)=-(dx**2+dy**2)         !
c
        DO j=2,Y-1                         !
           DO i=2,X/2-1                    !
              k=(j-1)*X/2+i                !
              A(k,k-X/2)=dx**2             !
              A(k,k-1)=dy**2               !
              A(k,k)=-2.0*(dx**2+dy**2)    ! Inner (x<0) cells
              A(k,k+1)=dy**2               !
              A(k,k+X/2)=dx**2             !
           ENDDO                           !
        ENDDO
c
c Link cells, right below the step (start)
c
       j=1                            !
       i=X/2                          !
         k=(j-1)*X/2+i                !
         A(k,k-1)=dy**2               ! Under step (x<0:bottom) cell
         A(k,k)=-(dx**2+2.0*dy**2)    ! 
         A(k,(X/2)*Y+1)=dy**2         !
         A(k,k+X/2)=dx**2             !
c
         i=X/2                               !
         DO j=2,Y/gamma                      !
            k=(j-1)*X/2+i                    !
            A(k,k-X/2)=dx**2                 !
            A(k,k-1)=dy**2                   !
            A(k,k)=-2.0*(dx**2+dy**2)        ! Under step (x<0) cells
            A(k,(X/2)*Y+1+(j-1)*X/2)=dy**2   !
            A(k,k+X/2)=dx**2                 !
         ENDDO                               !
c
       j=1                            !
c       i=X/2+1                       !
         k=(X/2)*Y+1                  !
         A(k,X/2)=dy**2               ! Under step (x>0:bottom) cell
         A(k,k)=-(dx**2+2.0*dy**2)    ! 
         A(k,k+1)=dy**2               !
         A(k,k+X/2)=dx**2             !
c
c         i=X/2+1                             !
         DO j=2,Y/gamma-1                    !
            k=(X/2)*Y+1+(j-1)*X/2            !
            A(k,k-X/2)=dx**2                 !
            A(k,j*X/2)=dy**2                 !
            A(k,k)=-2.0*(dx**2+dy**2)        ! Under step (x>0) cells
            A(k,k+1)=dy**2                   !
            A(k,k+X/2)=dx**2                 !
         ENDDO                               !
c
        j=Y/gamma                       !
c        i=X/2+1                         !
           k=(X/2)*Y+1+(j-1)*X/2        !
           A(k,k-X/2)=dx**2             !
           A(k,j*X/2)=dy**2             !  Under step (x>0:top) boundary cell
           A(k,k)=-(dx**2+2.0*dy**2)    ! 
           A(k,k+1)=dy**2               !
c
c Link cells, right below the step (end)
c
        j=1                             !
        DO i=X/2+2,X-1                  !
           k=(X/2)*Y-X/2+i              !
           A(k,k-1)=dy**2               ! Bottom (x>0) boundary cells
           A(k,k)=-(dx**2+2.0*dy**2)    ! 
           A(k,k+1)=dy**2               !
           A(k,k+X/2)=dx**2             !
        ENDDO                           !
c
        j=Y/gamma                       !
        DO i=X/2+2,X-1                  !
           k=(X/2)*Y-X/2+(j-1)*X/2+i    !
           A(k,k-X/2)=dx**2             !
           A(k,k-1)=dy**2               ! Top (x>0) boundary cells
           A(k,k)=-(dx**2+2.0*dy**2)    ! 
           A(k,k+1)=dy**2               !
        ENDDO                           !
c
        i=X                             !
        DO j=2,Y/gamma-1                !
           k=(X/2)*Y-X/2+(j-1)*X/2+i    !
           A(k,k-X/2)=dx**2             !
           A(k,k-1)=dy**2               ! Right (vertical) boundary cells
           A(k,k)=-(2.0*dx**2+dy**2)    !
           A(k,k+X/2)=dx**2             !
        ENDDO       
c
        i=X                           !
c        j=1                           !
        k=(X/2)*Y-X/2+i               !
        A(k,k-1)=dy**2                ! Bottom right corner cell
        A(k,k)=-(dx**2+dy**2)         ! 
        A(k,k+X/2)=dx**2              !
c
        i=X                         !
        j=Y/gamma                   !
        k=(X/2)*Y-X/2+(j-1)*X/2+i   !
        A(k,k-X/2)=dx**2            ! Top right corner cell
        A(k,k-1)=dy**2              !
        A(k,k)=-(dx**2+dy**2)       !
c
        DO j=2,Y/gamma-1                   !
           DO i=X/2+2,X-1                  !
              k=(X/2)*Y+(X/2)*(j-2)+i      !
              A(k,k+X/2)=dx**2             !
              A(k,k-1)=dy**2               !
              A(k,k)=-2.0*(dx**2+dy**2)    ! Inner cells
              A(k,k+1)=dy**2               !
              A(k,k-X/2)=dx**2             !
           ENDDO                           !
        ENDDO
c
      END SUBROUTINE Matrix 
c
c ======================================================================
c
c To find out if there're nonzero entries in each of the rows.
c
      SUBROUTINE Check_Matrix
         USE Global_Var
         DOUBLE PRECISION :: temp
         OPEN(UNIT=102,FILE="Check.matrix",STATUS="REPLACE")
         DO i=1,Y*X/2+Y/gamma*X/2
            temp=0.0
            DO j=1,Y*X/2+Y/gamma*X/2
               IF (ABS(A(i,j)).GT.temp) THEN 
                  temp=ABS(A(i,j))
               ENDIF
            ENDDO
            WRITE(102,*)"Row",i,"Greatest entry", temp
         ENDDO
         CLOSE(102)
      END SUBROUTINE Check_Matrix
c
c ======================================================================
c
      SUBROUTINE bc(u,v)
c
        USE Global_Var
        DOUBLE PRECISION, DIMENSION(X+1,Y+1) :: u,v
        DOUBLE PRECISION :: psitop
c
c For symmetry centre boundary
c   upstream (left) end
        psitop=0.0
        DO  j=1,Y
          u(1,j)=3.0/2.0*(1-(j-0.5)*dy*(j-0.5)*dy)
          psitop=psitop+u(1,j)*dy
        ENDDO
        u(1,:)=u(1,:)/psitop
c   downstream (right) end
        psitop=0.0
        DO  j=1,Y/gamma
          u(X+1,j)=3.0/2.0*gamma*(1-(j-0.5)*dy*(j-0.5)*dy*gamma**2)
          psitop=psitop+u(X+1,j)*dy
        ENDDO
        u(X+1,:)=u(X+1,:)/psitop
c
c++++++++++++++++++++++++++++++
c For no-slip centre boundary
c   upstream (left) end
c        psitop=0.0
c        DO  j=1,Y
c          u(1,j)=3.0/2.0*(j-0.5)*dy*(1-(j-0.5)*dy)
c          psitop=psitop+u(1,j)*dy
c        ENDDO
c        u(1,:)=u(1,:)/psitop
c   downstream (right) end
c        psitop=0.0
c        DO  j=1,Y/gamma
c          u(X+1,j)=3.0/2.0*gamma
c     $             *(j-0.5)*dy*gamma*(1-(j-0.5)*dy*gamma)
c          psitop=psitop+u(X+1,j)*dy
c        ENDDO
c        u(X+1,:)=u(X+1,:)/psitop
c++++++++++++++++++++++++++++++
c
         DO  j=Y/gamma+1,Y               !
            u(X/2+1,j)=0.0               ! at the step
         ENDDO                           !
c 
         DO i=1,X               !
            v(i,1)=0.0          ! bottom
         ENDDO                  !
c
         DO i=1,X/2             !
            v(i,Y+1)=0.0        ! left of step top
         ENDDO                  !
c
         DO i=X/2+1,X           !
            v(i,Y/gamma+1)=0.0    ! right of step top
         ENDDO                  !
c
      END SUBROUTINE bc
c
c ====================================================================
c
      SUBROUTINE ic(u,v) ! initial condition
         USE Global_Var
         DOUBLE PRECISION, DIMENSION(X+1,Y+1) :: u,v
         u=0.0
         v=0.0
         CALL bc(u,v)
      END SUBROUTINE ic  ! initial condition
c
c ===================================================================
c
      SUBROUTINE CopyVals
         USE Global_Var
         u_n=u_n_plus_1
         v_n=v_n_plus_1
      END SUBROUTINE CopyVals
c
c ===================================================================
c
      SUBROUTINE CopyVals_Star
         USE Global_Var
         u_star=u_n_plus_1
         v_star=v_n_plus_1
      END SUBROUTINE CopyVals_Star
c
c ====================================================================
c
      SUBROUTINE UV_Stars 
        USE Global_Var
        DOUBLE PRECISION u_CDconv
        EXTERNAL u_CDconv
        DOUBLE PRECISION v_CDconv
        EXTERNAL v_CDconv
        DOUBLE PRECISION u_UPconv
        EXTERNAL u_UPconv
        DOUBLE PRECISION v_UPconv
        EXTERNAL v_UPconv
        DOUBLE PRECISION u_Qconv
        EXTERNAL u_Qconv
        DOUBLE PRECISION v_Qconv
        EXTERNAL v_Qconv
        DOUBLE PRECISION :: uo,due,duw,dun,dus
     $                      vo,dve,dvw,dvn,dvs
c
c \\\\\\\\\\\\ left of step (begin)
c
c
        DO j=1,Y
          DO i=2,X/2
            uo=u_n(i,j)
            duw=uo-u_n(i-1,j)
            due=u_n(i+1,j)-uo
            if(j.eq.1)then
c              dus=3.0*uo-u_n(i,j+1)/3.0  ! for no-slip boundary
              dus=0.0                    ! for symmetry boundary
            else
              dus=uo-u_n(i,j-1)
            endif
            if(j.eq.Y)then
              dun=-(3.0*uo-u_n(i,j-1)/3.0)
            else
              dun=u_n(i,j+1)-uo
            endif
                IF (method.EQ.0) THEN
                  u_star(i,j)=u_n(i,j)
     $                 +(dt*nu/dx**2)*(due-duw)
     $                 +(dt*nu/dy**2)*(dun-dus)
                ELSE
                  IF (method.EQ.1) THEN
                    u_star(i,j)= u_n(i,j)
     $                   +(dt/Re/dx**2)*(due-duw)
     $                   +(dt/Re/dy**2)*(dun-dus)-dt*u_CDconv(u_n,v_n)
                  ELSE
                    IF (method.EQ.2) THEN
                      u_star(i,j)=u_n(i,j)
     $                     +(dt/Re/dx**2)*(due-duw)
     $                     +(dt/Re/dy**2)*(dun-dus)-dt*u_UPconv(u_n,v_n)
                    ELSE
                      IF (method.EQ.3) THEN
                        u_star(i,j)=u_n(i,j)
     $                      +(dt/Re/dx**2)*(due-duw)
     $                      +(dt/Re/dy**2)*(dun-dus)-dt*u_Qconv(u_n,v_n)
                      ENDIF
                    ENDIF
                  ENDIF
                ENDIF
              ENDDO
            ENDDO
c
         DO j=2,Y
            DO i=1,X/2
               vo=v_n(i,j)
               dvs=vo-v_n(i,j-1)
               dvn=v_n(i,j+1)-vo
               if(i.eq.1)then
                 dvw=3.0*vo-v_n(i+1,j)/3.0
               else
                 dvw=vo-v_n(i-1,j)
               endif
               if(i.eq.X/2.and.j.gt.y/gamma)then
                 dve=-(3.0*vo-v_n(i-1,j)/3.0)
               else
                 dve=v_n(i+1,j)-vo
               endif
               IF (method.EQ.0) THEN
                 v_star(i,j)=v_n(i,j)
     $                +(dt*nu/dx**2)*(dve-dvw)
     $                +(dt*nu/dy**2)*(dvn-dvs)
               ELSE
                 IF (method.EQ.1) THEN
                   v_star(i,j)=v_n(i,j)
     $                  +(dt/Re/dx**2)*(dve-dvw)
     $                  +(dt/Re/dy**2)*(dvn-dvs)-dt*v_CDconv(u_n,v_n)
                 ELSE
                   IF (method.EQ.2) THEN
                     v_star(i,j)=v_n(i,j)
     $                    +(dt/Re/dx**2)*(dve-dvw)
     $                    +(dt/Re/dy**2)*(dvn-dvs)-dt*v_UPconv(u_n,v_n)
                   ELSE
                     IF (method.EQ.3) THEN
                       v_star(i,j)=v_n(i,j)
     $                      +(dt/Re/dx**2)*(dve-dvw)
     $                      +(dt/Re/dy**2)*(dvn-dvs)-dt*v_Qconv(u_n,v_n)
                     ENDIF
                   ENDIF
                 ENDIF
               ENDIF 
             ENDDO
           ENDDO
c
        DO j=1,Y/gamma
          DO i=X/2+1,X
            uo=u_n(i,j)
            duw=uo-u_n(i-1,j)
            due=u_n(i+1,j)-uo
            if(j.eq.1)then
c              dus=3.0*uo-u_n(i,j+1)/3.0  ! for no-slip boundary
              dus=0.0                    ! for symmetry boundary
            else
              dus=uo-u_n(i,j-1)
            endif
            if(j.eq.Y/gamma)then
              dun=-(3.0*uo-u_n(i,j-1)/3.0)
            else
              dun=u_n(i,j+1)-uo
            endif
            IF (method.EQ.0) THEN
              u_star(i,j)=u_n(i,j)
     $             +(dt*nu/dx**2)*(due-duw)
     $             +(dt*nu/dy**2)*(dun-dus)
            ELSE
              IF (method.EQ.1) THEN
                u_star(i,j)=u_n(i,j)
     $               +(dt/Re/dx**2)*(due-duw)
     $               +(dt/Re/dy**2)*(dun-dus)-dt*u_CDconv(u_n,v_n)
              ELSE
                IF (method.EQ.2) THEN
                  u_star(i,j)=u_n(i,j)
     $                 +(dt/Re/dx**2)*(due-duw)
     $                 +(dt/Re/dy**2)*(dun-dus)-dt*u_UPconv(u_n,v_n)
                ELSE
                  IF (method.EQ.3) THEN
                    u_star(i,j)=u_n(i,j)
     $                   +(dt/Re/dx**2)*(due-duw)
     $                   +(dt/Re/dy**2)*(dun-dus)-dt*u_Qconv(u_n,v_n)
                  ENDIF
                ENDIF
              ENDIF
            ENDIF
          ENDDO
        ENDDO
c
        DO j=2,Y/gamma
          DO i=X/2+1,X
            vo=v_n(i,j)
            dvs=vo-v_n(i,j-1)
            dvn=v_n(i,j+1)-vo
            dvw=vo-v_n(i-1,j)
            if(i.eq.X)then
              dve=-(3.0*vo-v_n(i-1,j)/3.0)
            else
              dve=v_n(i+1,j)-vo
            endif
            IF (method.EQ.0) THEN
              v_star(i,j)=v_n(i,j)
     $             +(dt*nu/dx**2)*(dve-dvw)
     $             +(dt*nu/dy**2)*(dvn-dvs)
            ELSE
              IF (method.EQ.1) THEN
                v_star(i,j)=v_n(i,j)
     $               +(dt/Re/dx**2)*(dve-dvw)
     $               +(dt/Re/dy**2)*(dvn-dvs)-dt*v_CDconv(u_n,v_n)
              ELSE 
                IF (method.EQ.2) THEN
                  v_star(i,j)=v_n(i,j)
     $                 +(dt/Re/dx**2)*(dve-dvw)
     $                 +(dt/Re/dy**2)*(dvn-dvs)-dt*v_UPconv(u_n,v_n)
                ELSE 
                  IF (method.EQ.3) THEN
                    v_star(i,j)=v_n(i,j)
     $                   +(dt/Re/dx**2)*(dve-dvw)
     $                   +(dt/Re/dy**2)*(dvn-dvs)-dt*v_Qconv(u_n,v_n)
                  ENDIF
                ENDIF
              ENDIF
            ENDIF 
          ENDDO
        ENDDO
c
c \\\\\\\\\\\\ right of step (end)
c
c         CALL bc(u_star,v_star) 
c
      END SUBROUTINE UV_Stars
c
c ====================================================================
c
         DOUBLE PRECISION  FUNCTION u_CDconv(u,v)
         USE Global_Var
         DOUBLE PRECISION, DIMENSION(X+1,Y+1) :: u,v
         DOUBLE PRECISION :: upb,ul,up,ur,upt,
     $                       vs,uw,ue,vn, ! convecting velocities
     $                       Cb,Cl,Cr,Ct
c
         ul=u(i-1,j)
         up=u(i,j)
         ur=u(i+1,j)
c
         IF (j.EQ.1) THEN
           upb=0.0
         ELSE 
           upb=u(i,j-1)+up
         ENDIF
c
         IF ((j.EQ.Y).OR.((j.EQ.Y/gamma).AND.(i.GT.X/2+1))) THEN
           upt=0.0
         ELSE
           upt=up+u(i,j+1)
         ENDIF
c
         vs=(v(i-1,j)+v(i,j))/2.0
         uw=(ul+up)/2.0
         ue=(up+ur)/2.0
         vn=(v(i-1,j+1)+v(i,j+1))/2.0
c
         Cb=vs/dy
         Cl=uw/dx
         Cr=ue/dx
         Ct=vn/dy
c
         u_CDconv = Cr*ue-Cl*uw
     $             +Ct*upt/2.0-Cb*upb/2.0
c
         END FUNCTION u_CDconv
c
c ================================================================
c
         DOUBLE PRECISION FUNCTION v_CDconv(u,v)
         USE Global_Var
         DOUBLE PRECISION, DIMENSION(X+1,Y+1) :: u,v
         DOUBLE PRECISION :: vb,vpl,vp,vpr,vt,
     $                       vs,uw,ue,vn,
     $                       Cb,Cl,Cr,Ct  
c
         vb=v(i,j-1)
         vp=v(i,j)
         vt=v(i,j+1)
c
         IF (i.EQ.1) THEN
           vpl=0.0
         ELSE
           vpl=v(i-1,j)+vp
         ENDIF
c
         IF (((i.EQ.X/2).AND.(j.GT.Y/gamma)).OR.(i.EQ.X)) THEN
           vpr=0.0
         ELSE
           vpr=vp+v(i+1,j)
         ENDIF
c
         vs=(vb+vp)/2.0
         uw=(u(i,j-1)+u(i,j))/2.0
         ue=(u(i+1,j-1)+u(i+1,j))/2.0
         vn=(vp+vt)/2.0
c
         Cb=vs/dy
         Cl=uw/dx
         Cr=ue/dx
         Ct=vn/dy
c
         v_CDconv = Cr*vpr/2.0-Cl*vpl/2.0
     $             +Ct*vn-Cb*vs
c
         END FUNCTION v_CDconv
c
c ====================================================================
c
      DOUBLE PRECISION FUNCTION u_UPconv(u,v) 
         USE Global_Var
         DOUBLE PRECISION, DIMENSION(X+1,Y+1) :: u,v
         DOUBLE PRECISION :: ub,ul,up,ur,ut,
     $                       vs,uw,ue,vn,
     $                       swvs1,swvs2,swuw1,swuw2,
     $                       swue1,swue2,swvn1,swvn2,
     $                       Cb,Cl,Cr,Ct
c
         ul=u(i-1,j)
         up=u(i,j)
         ur=u(i+1,j)
c
         IF (j.EQ.1) THEN
           ub=up
         ELSE
           ub=u(i,j-1)
         ENDIF
c
         IF ((j.EQ.Y).OR.((j.EQ.Y/gamma).AND.(i.GT.X/2+1))) THEN
           ut=-up
         ELSE
           ut=u(i,j+1)
         ENDIF
c
         vs=(v(i-1,j)+v(i,j))/2.0
         uw=(ul+up)/2.0
         ue=(up+ur)/2.0
         vn=(v(i-1,j+1)+v(i,j+1))/2.0
c
         swvs1=(vs+ABS(vs))/2.0
         swvs2=(vs-ABS(vs))/2.0
         swuw1=(uw+ABS(uw))/2.0
         swuw2=(uw-ABS(uw))/2.0
         swue1=(ue+ABS(ue))/2.0
         swue2=(ue-ABS(ue))/2.0
         swvn1=(vn+ABS(vn))/2.0
         swvn2=(vn-ABS(vn))/2.0
c
         Cb=1.0/dy
         Cl=1.0/dx
         Cr=Cl
         Ct=Cb
c
         u_UPconv = Cr*(swue1*up+swue2*ur)-Cl*(swuw1*ul+swuw2*up)
     $             +Ct*(swvn1*up+swvn2*ut)-Cb*(swvs1*ub+swvs2*up)
c
         END  FUNCTION u_UPconv
c
c ===================================================================
c
         DOUBLE PRECISION FUNCTION v_UPconv(u,v)
         USE Global_Var
         DOUBLE PRECISION, DIMENSION(X+1,Y+1) :: u,v
         DOUBLE PRECISION :: vb,vl,vp,vr,vt,
     $                       vs,uw,ue,vn,
     $                       swvs1,swvs2,swuw1,swuw2,
     $                       swue1,swue2,swvn1,swvn2,
     $                       Cb,Cl,Cr,Ct
c
         vb=v(i,j-1)
         vp=v(i,j)
         vt=v(i,j+1)
c
         IF (i.EQ.1) THEN
           vl=-vp
         ELSE
           vl=v(i-1,j)
         ENDIF
c
         IF (((i.EQ.X/2).AND.(j.GT.Y/gamma+1)).OR.(i.EQ.X)) THEN
           vr=-vp
         ELSE
           vr=v(i+1,j)
         ENDIF
c
         vs=(vb+vp)/2.0
         uw=(u(i,j-1)+u(i,j))/2.0
         ue=(u(i+1,j-1)+u(i+1,j))/2.0
         vn=(vp+vt)/2.0
c
         swvs1=(vs+ABS(vs))/2.0
         swvs2=(vs-ABS(vs))/2.0
         swuw1=(uw+ABS(uw))/2.0
         swuw2=(uw-ABS(uw))/2.0
         swue1=(ue+ABS(ue))/2.0
         swue2=(ue-ABS(ue))/2.0
         swvn1=(vn+ABS(vn))/2.0
         swvn2=(vn-ABS(vn))/2.0
c
         Cb=1.0/dy
         Cl=1.0/dx
         Cr=Cl
         Ct=Cb
c
         v_UPconv = Cr*(swue1*vp+swue2*vr)-Cl*(swuw1*vl+swuw2*vp)
     $             +Ct*(swvn1*vp+swvn2*vt)-Cb*(swvs1*vb+swvs2*vp)
c
         END FUNCTION v_UPconv
c
c ===============================================================
c
         DOUBLE PRECISION FUNCTION u_Qconv(u,v) 
         USE Global_Var
         DOUBLE PRECISION, DIMENSION(X+1,Y+1) :: u,v
         DOUBLE PRECISION :: upbb,upb,upll,ul,up,ur,uprr,upt,uptt,
     $                       vs,uw,ue,vn,      ! convecting velocities
c velocity switches (sw***) : 1 +'ive and 2 -'ive directions
     $                       swue1,swue2,swuw1,swuw2,
     $                       swvn1,swvn2,swvs1,swvs2,
     $                       Cr,Cl,Ct,Cb
c
         ul =u(i-1,j)
         up =u(i,j)
         ur =u(i+1,j)
c                                                 ! bottom bcells(begin)
         IF (j.EQ.1) THEN
           upbb=u(i,j+1)+up
           upb =2.0*up
         ELSE 
           IF (j.EQ.2) THEN
             upbb=u(i,j-1)+up
             upb =u(i,j-1)+up
           ELSE  
               upbb=u(i,j-2)+up
               upb =u(i,j-1)+up
           ENDIF
         ENDIF                                      ! bottom b-cells(end)
c                                                   ! top b-cells(begin)
         IF ((j.EQ.Y).OR.((j.EQ.Y/gamma).AND.(i.GT.X/2+1))) THEN 
           uptt=up-u(i,j-1)
           upt =0.0
         ELSE  
           IF ((j.EQ.Y-1).OR.((j.EQ.Y/gamma-1).AND.(i.GT.X/2+1))) THEN
             uptt=up-u(i,j+1)
             upt =up+u(i,j+1)
           ELSE  
             uptt=up+u(i,j+2)
             upt =up+u(i,j+1)
           ENDIF
         ENDIF                        ! top b-cells (end)
c        
         IF (i.EQ.2) THEN
           upll=2.0*ul
         ELSE
           upll=u(i-2,j)+up
         ENDIF 
c
         IF (((i.EQ.X/2).AND.(j.GT.Y/gamma)).OR.(i.EQ.X)) THEN
           uprr=2.0*ur
         ELSE
           uprr=up+u(i+2,j)
         ENDIF 
c
         vs=(v(i-1,j)+v(i,j))/2.0
         uw=(ul+up)/2.0
         ue=(up+ur)/2.0
         vn=(v(i-1,j+1)+v(i,j+1))/2.0 
c
         swue1=(ue+ABS(ue))/2.0
         swue2=(ue-ABS(ue))/2.0
         swuw1=(uw+ABS(uw))/2.0
         swuw2=(uw-ABS(uw))/2.0
         swvn1=(vn+ABS(vn))/2.0
         swvn2=(vn-ABS(vn))/2.0
         swvs1=(vs+ABS(vs))/2.0 
         swvs2=(vs-ABS(vs))/2.0 
c
         Cr=1.0/dx                      ! division by rho and dy*dx was
         Cl=Cr                      ! done, convecting velocities used 
         Ct=1.0/dy                      ! to multiply in switches
         Cb=Ct  
c
         u_Qconv= Cr*(swue1*(ue-(ul+ur-2.0*up)/8.0)
     $              +swue2*(ue-(uprr-2.0*ur)/8.0))
     $           -Cl*(swuw1*(uw-(upll-2.0*ul)/8.0)
     $              +swuw2*(uw-(ul+ur-2.0*up)/8.0))
     $           +Ct*(swvn1*((upt)/2.0-(upb-2.0*up+upt-2.0*up)/8.0)
     $              +swvn2*((upt)/2.0-(uptt-2.0*(upt-up))/8.0))
     $           -Cb*(swvs1*((upb)/2.0-(upbb-2.0*(upb-up))/8.0)
     $              +swvs2*((upb)/2.0-(upb-2.0*up+upt-2.0*up)/8.0))
c     
         END FUNCTION u_Qconv
c
c ===============================================================
c
         DOUBLE PRECISION FUNCTION v_Qconv(u,v) 
         USE Global_Var
         DOUBLE PRECISION, DIMENSION(X+1,Y+1) :: u,v
         DOUBLE PRECISION :: vpbb,vb,vpll,vpl,vp,vpr,vprr,vt,vptt,
     $                       vs,uw,ue,vn,      ! convecting velocities
c velocity switches (sw***) : 1 +'ive and 2 -'ive directions
     $                       swue1,swue2,swuw1,swuw2,
     $                       swvn1,swvn2,swvs1,swvs2,
     $                       Cr,Cl,Ct,Cb
c
         vb =v(i,j-1)
         vp =v(i,j)
         vt =v(i,j+1)
c
         IF (i.EQ.1) THEN                   ! left b-cells (begin)
           vpll=vp-v(i+1,j)
           vpl =0.0
         ELSE  
           IF (i.EQ.2) THEN
             vpll=vp-v(i-1,j)
             vpl =v(i-1,j)+vp
           ELSE  
               vpll=v(i-2,j)+vp
               vpl =v(i-1,j)+vp
           ENDIF                      ! left b-cells (end)
         ENDIF 
c                                     ! right b-cells (begin) & step cells
         IF (((i.EQ.X/2).AND.(j.GT.Y/gamma+1)).OR.(i.EQ.X)) THEN
           vprr=vp-v(i-1,j)
           vpr =0.0
         ELSE  
           IF (((i.EQ.X/2-1).AND.(j.GT.Y/gamma+1)).OR.(i.EQ.X-1)) THEN
             vprr=vp-v(i+1,j)
             vpr =vp+v(i+1,j)
           ELSE  
               vprr=vp+v(i+2,j)
               vpr =vp+v(i+1,j)
           ENDIF
         ENDIF 
c        
         IF (j.EQ.2) THEN
           vpbb=0.0
         ELSE
           vpbb=v(i,j-2)+vp
         ENDIF 
c
         IF ((j.EQ.Y).OR.((j.EQ.Y/gamma).AND.(i.GT.X/2))) THEN
           vptt=0.0
         ELSE
           vptt=vp+v(i,j+2)
         ENDIF 
c
         vs=(vb+vp)/2.0
         uw=(u(i,j-1)+u(i,j))/2.0
         ue=(u(i+1,j-1)+u(i+1,j))/2.0
         vn=(vp+vt)/2.0
c
         swue1=(ue+ABS(ue))/2.0
         swue2=(ue-ABS(ue))/2.0
         swuw1=(uw+ABS(uw))/2.0
         swuw2=(uw-ABS(uw))/2.0
         swvn1=(vn+ABS(vn))/2.0
         swvn2=(vn-ABS(vn))/2.0
         swvs1=(vs+ABS(vs))/2.0 
         swvs2=(vs-ABS(vs))/2.0 
c
         Cr=1.0/dx                 ! division by rho and dy*dx was
         Cl=Cr                     ! done
         Ct=1.0/dy
         Cb=Ct
c
         v_Qconv= Cr*(swue1*((vpr)/2.0-(vpl-2.0*vp+vpr-2.0*vp)/8.0)
     $              +swue2*((vpr)/2.0-(vprr-2.0*(vpr-vp))/8.0))
     $           -Cl*(swuw1*((vpl)/2.0-(vpll-2.0*(vpl-vp))/8.0)
     $              +swuw2*((vpl)/2.0-(vpl-2.0*vp+vpr-2.0*vp)/8.0))
     $           +Ct*(swvn1*(vn-(vb+vt-2.0*vp)/8.0)
     $              +swvn2*(vn-(vptt-2.0*vt)/8.0))
     $           -Cb*(swvs1*(vs-(vpbb-2.0*vb)/8.0)
     $              +swvs2*(vs-(vb+vt-2.0*vp)/8.0))
c     
         END FUNCTION v_Qconv
c
c ======================================================================
c
c Named the rhs p because LAPACK will overwrite the rhs matrix & return 
c result under this name. We initially set all entries in p to zero.
c
       SUBROUTINE Rhs_Column
        USE Global_Var
        DOUBLE PRECISION :: ue,uw,vn,vs
c
        p=0.0     ! to set all entries to zero
c
c Left of step cells
        DO j=1,Y
           DO i=1,X/2
              k=(j-1)*X/2+i
              uw=u_star(i,j)
              ue=u_star(i+1,j)
              vs=v_star(i,j)  
              vn=v_star(i,j+1)
              if(i.eq.1)uw=u_n(i,j)
              if(i.eq.X/2.and.j.gt.Y/gamma)ue=u_n(i+1,j)
              if(j.eq.1)vs=v_n(i,j)
              if(j.eq.Y)vn=v_n(i,j+1)
c
              p(k)=(dx*dy/dt)*((ue-uw)*dy+(vn-vs)*dx)
           ENDDO
        ENDDO
c
c Right of step cells
        DO j=1,Y/gamma
           DO i=X/2+1,X
              k=Y*X/2-X/2+(j-1)*X/2+i
              uw=u_star(i,j)
              ue=u_star(i+1,j)
              vs=v_star(i,j) 
              vn=v_star(i,j+1)
              if(i.eq.X)ue=u_n(i+1,j) 
              if(j.eq.1)vs=v_n(i,j)
              if(j.eq.Y/gamma)vn=v_n(i,j+1)
c
              p(k)=(dx*dy/dt)*((ue-uw)*dy+(vn-vs)*dx)
           ENDDO
        ENDDO
c
        p(1)=0.0        ! to set ambient level of pressure at bottom left
c
       END SUBROUTINE Rhs_Column
c
c ========================================================================
c
       SUBROUTINE UV_n_plus_1
         USE Global_Var
c
c \\\\\\\\\\\\\\\\\\\\\\ left of step (begin)
c
         DO j=1,Y
            DO i=2,X/2
               k=(j-1)*X/2+i
               u_n_plus_1(i,j)=u_star(i,j)-dt*(p(k)-p(k-1))/dx
            ENDDO
         ENDDO
c
         DO j=2,Y
            DO i=1,X/2 
               k=(j-1)*X/2+i
               v_n_plus_1(i,j)=v_star(i,j)-dt*(p(k)-p(k-X/2))/dy
            ENDDO
         ENDDO
c
c \\\\\\\\\\\\\\\\\\\\\\ left of step (end)
c
c \\\\\\\\\\\\\\\\\\\\\\ under the step (begin)
c
         i=X/2+1
         DO j=1,Y/gamma
            k=Y*X/2-X/2+(j-1)*X/2+i
            u_n_plus_1(i,j)=u_star(i,j)-dt*(p(k)-p(j*X/2))/dx
         ENDDO
c
c \\\\\\\\\\\\\\\\\\\\\\ under the step (end)
c
c \\\\\\\\\\\\\\\\\\\\\\ right of the step (begin)
c
         DO j=1,Y/gamma
            DO i=X/2+2,X
               k=Y*X/2-X/2+(j-1)*X/2+i
               u_n_plus_1(i,j)=u_star(i,j)-dt*(p(k)-p(k-1))/dx
            ENDDO
         ENDDO
c
         DO j=2,Y/gamma
            DO i=X/2+1,X 
               k=Y*X/2-X/2+(j-1)*X/2+i
               v_n_plus_1(i,j)=v_star(i,j)-dt*(p(k)-p(k-X/2))/dy
            ENDDO
         ENDDO
c
c \\\\\\\\\\\\\\\\\\\\\\ right of the step (end)
c
         CALL bc(u_n_plus_1,v_n_plus_1)
c
       END SUBROUTINE UV_n_plus_1
c
c ======================================================================== 
c
       SUBROUTINE Calc_Psi
          USE Global_Var
          do i=1,X+1
            psi(i,1)=0.0
            do j=2,Y+1
              psi(i,j)=psi(i,j-1)+u_n(i,j-1)*dy
            enddo
          enddo
c
c          DO i=2,X+1
c            psiv(i,1)=0.0
c            DO j=2,Y+1
c              psiv(i,j)=psiv(i-1,j)-v_n(i-1,j)*dx
c            ENDDO
c          ENDDO
       END SUBROUTINE Calc_Psi
c
c ======================================================================== 
c
       SUBROUTINE Calc_Div
          USE Global_Var
          do j=1,Y
            do i=1,X/2
              div(i,j)=(u_n(i+1,j)-u_n(i,j))/dx
     $               + (v_n(i,j+1)-v_n(i,j))/dy
            enddo
          enddo
         do j=1,Y/gamma
            do i=X/2+1,X
              div(i,j)=(u_n(i+1,j)-u_n(i,j))/dx
     $               + (v_n(i,j+1)-v_n(i,j))/dy
            enddo
          enddo
       END SUBROUTINE Calc_Div
c
c ========================================================================
c
       SUBROUTINE Wvorticity
         USE Global_Var
c
c  upstream wall vortex
c                  
c         DOUBLE PRECISION, DIMENSION(X/2+1) :: wv
c         OPEN(UNIT=100,FILE=Wvort,STATUS="REPLACE")
c
c         DO i=1,X/2+1
c              wv(i)=(3.0*u_n(i,j)-u_n(i,j-1)/3.0)/dy
c         ENDDO
c         DO i=2,X/2+1
c           IF ((wv(i-1).GT.0.0).AND.
c     $          ((wv(i).LT.0.0)).OR.((wv(i).EQ.0.0))) THEN
c             WRITE(100,10001) (i-2)*dx,(i-1)*dx
c             WRITE(100,10002) wv(i-1),wv(i)
c           ENDIF
c         ENDDO
c         WRITE(100,*) " "
c         WRITE(100,*) " "
c         WRITE(100,*) "   X ","          ","w-vorticity"
c         DO i=1,X/2+1
c           WRITE(100,10003)(i-1)*dx-Xm,wv(i)
c         ENDDO
c
         DOUBLE PRECISION, DIMENSION(X/2+1:X+1) :: wv
         OPEN(UNIT=100,FILE=Wvort,STATUS="REPLACE")
         j=Y/gamma              !    for downstream wall vorticity
         DO i=X/2+1,X+1
              wv(i)=(3.0*u_n(i,j)-u_n(i,j-1)/3.0)/dy
         ENDDO
         DO i=X/2+2,X+1
           IF ((wv(i-1).GT.0.0).AND.
     $          ((wv(i).LT.0.0)).OR.((wv(i).EQ.0.0))) THEN
             WRITE(100,10001) (i-2)*dx,(i-1)*dx
             WRITE(100,10002) wv(i-1),wv(i)
           ENDIF
         ENDDO
c
         WRITE(100,*) " "
         WRITE(100,*) " "
         WRITE(100,*) "   X ","          ","w-vorticity"
         DO i=X/2+1,X+1
           WRITE(100,10003)(i-1)*dx-Xm,wv(i)
         ENDDO
c
         CLOSE(100)
10001      FORMAT("Wall vorticity vanishes between ",F7.5," and ",F7.5)
10002      FORMAT("vorticity values are ",ES12.5," and ",ES12.5)
10003      FORMAT(2(ES12.5,"   "))
c
c subtracted 1 from both i & j because they run from 1, not from 0 for 
c computations, so as to get proper actual distances.
c
       END SUBROUTINE Wvorticity
c
c =======================================================================
c
       SUBROUTINE Separation_PsiMax_Points
          USE Global_Var
          DOUBLE PRECISION :: psisw,psis,psise,
     $                        psiw,psio,psie,
     $                        psinw,psin,psine , psimax
c
          OPEN(UNIT=100,FILE=SepPsiMax,STATUS="REPLACE")
          j=Y-1
          DO i=1,X/2
            IF ((psi(i,j).LT.1.0).AND.((psi(i+1,j).GT.1.0).OR.
     $           ((psi(i+1,j).EQ.1.0)))) THEN
              WRITE(100,*)"Upstream Separation Point is"
              WRITE(100,10002)(i+1)*dx,j*dy,psi(i+1,j)
              WRITE(100,*)""
              WRITE(100,*)""
            ENDIF
          ENDDO
c
          j=Y/gamma-1
          DO i=X/2+1,X+1
            IF ((psi(i,j).LT.1.0).AND.((psi(i+1,j).GT.1.0).OR.
     $           ((psi(i+1,j).EQ.1.0)))) THEN
              WRITE(100,*)"Downstream Separation Point is"
              WRITE(100,10002)(i+1)*dx,j*dy,psi(i+1,j)
              WRITE(100,*)""
              WRITE(100,*)""
            ENDIF
          ENDDO
c
          WRITE(100,*)"Psi Maxima"
c
          DO i=2,X/2
            DO j=2,Y-1
c
              psisw=psi(i-1,j-1)
              psis =psi(i,j-1)
              psise=psi(i+1,j-1)
              psiw =psi(i-1,j)
              psio =psi(i,j)
              psie =psi(i+1,j)
              psinw=psi(i-1,j+1)
              psin =psi(i,j+1)
              psine=psi(i+1,j+1)
c
              IF ((psio.GT.psisw.OR.psio.EQ.psisw).AND.
     $             (psio.GT.psis.OR.psio.EQ.psis).AND.
     $             (psio.GT.psise.OR.psio.EQ.psise).AND.
     $             (psio.GT.psiw.OR.psio.EQ.psiw).AND.
     $             (psio.GT.psie.OR.psio.EQ.psie).AND.
     $             (psio.GT.psinw.OR.psio.EQ.psinw).AND.
     $             (psio.GT.psin.OR.psio.EQ.psin).AND.
     $             (psio.GT.psine.OR.psio.EQ.psine)) THEN
                psimax=psio
              ENDIF
              IF (psimax.GT.0.0) THEN
                WRITE(100,10002)i*dx,j*dx,psimax
              ENDIF
            ENDDO
          ENDDO
c
          DO i=X/2+1,X
            DO j=2,Y/gamma-1
c
              psisw=psi(i-1,j-1)
              psis =psi(i,j-1)
              psise=psi(i+1,j-1)
              psiw =psi(i-1,j)
              psio =psi(i,j)
              psie =psi(i+1,j)
              psinw=psi(i-1,j+1)
              psin =psi(i,j+1)
              psine=psi(i+1,j+1)
c
              IF ((psio.GT.psisw.OR.psio.EQ.psisw).AND.
     $             (psio.GT.psis.OR.psio.EQ.psis).AND.
     $             (psio.GT.psise.OR.psio.EQ.psise).AND.
     $             (psio.GT.psiw.OR.psio.EQ.psiw).AND.
     $             (psio.GT.psie.OR.psio.EQ.psie).AND.
     $             (psio.GT.psinw.OR.psio.EQ.psinw).AND.
     $             (psio.GT.psin.OR.psio.EQ.psin).AND.
     $             (psio.GT.psine.OR.psio.EQ.psine)) THEN
                psimax=psio
              ENDIF
              IF (psimax.GT.0.0) THEN
                WRITE(100,10002)i*dx,j*dx,psimax
              ENDIF
            ENDDO
          ENDDO
c
          CLOSE(100)
10002     FORMAT("(",F7.4,",",F7.4,")",'  ',ES12.5)
c
       END SUBROUTINE Separation_PsiMax_Points
c 
c ========================================================================
c
      SUBROUTINE Write_Out_uvp
        USE Global_Var
c
        OPEN(UNIT=100,FILE=Uout,STATUS="REPLACE")
c
c        WRITE(100,*)"Length of tunnel & # of divisions:",2.0*Xm,X
c        WRITE(100,*)"Height of tunnel & # of divisions:",h,Y
c        WRITE(100,*)"So we have dx=",dx,"and dy=",dy 
c        WRITE(100,*)"Chosen time step=",dt
c        WRITE(100,*)"Convergence test EPSILON=",eps,"n=",n
c        WRITE(100,*)"Dynamic viscosity =",nu 
c        WRITE(100,*)"gamma =",gamma        
c        WRITE(100,*)" "
c        WRITE(100,*)"   ","X-axis","    ","Y-axis","        ",     
c     $              "u","             ","v","             ","p"
c     
         DO j=1,Y/gamma
           DO i=1,X+1
             WRITE(100,10000) i,j,u_n(i,j)
           ENDDO
         ENDDO
c
         DO j=Y/gamma+1,Y
           DO i=1,X/2+1
             WRITE(100,10000) i,j,u_n(i,j)
           ENDDO
         ENDDO
         CLOSE(100)
c
        OPEN(UNIT=101,FILE=Vout,STATUS="REPLACE")
c
c        WRITE(101,*)"Length of tunnel & # of divisions:",2.0*Xm,X
c        WRITE(101,*)"Height of tunnel & # of divisions:",h,Y
c        WRITE(101,*)"So we have dx=",dx,"and dy=",dy 
c        WRITE(101,*)"Chosen time step=",dt
c        WRITE(101,*)"Convergence test EPSILON=",eps,"n=",n
c        WRITE(101,*)"Dynamic viscosity =",nu 
c        WRITE(101,*)"gamma =",gamma        
c        WRITE(101,*)" "
c        WRITE(101,*)"   ","X-axis","    ","Y-axis","        ",
c     $              "u","             ","v","             ","p"
c
         DO j=1,Y/gamma+1
           DO i=1,X
             WRITE(101,10000) i,j,v_n(i,j)
           ENDDO
         ENDDO
c
         DO j=Y/gamma+2,Y+1
           DO i=1,X/2
             WRITE(101,10000) i,j,v_n(i,j)
           ENDDO
         ENDDO
         CLOSE(101)
c
        OPEN(UNIT=102,FILE=Pout,STATUS="REPLACE")
c
c        WRITE(102,*)"Length of tunnel & # of divisions:",2.0*Xm,X
c        WRITE(102,*)"Height of tunnel & # of divisions:",h,Y
c        WRITE(102,*)"So we have dx=",dx,"and dy=",dy 
c        WRITE(102,*)"Chosen time step=",dt
c        WRITE(102,*)"Convergence test EPSILON=",eps,"n=",n
c        WRITE(102,*)"Dynamic viscosity =",nu 
c        WRITE(102,*)"gamma =",gamma        
c        WRITE(102,*)" "
c        WRITE(102,*)"   ","X-axis","    ","Y-axis","        ",
c     $              "u","             ","v","             ","p"
c
         DO j=1,Y/gamma
           DO i=1,X
             IF(i.LE.X/2)THEN
               k=(j-1)*X/2+i
             ELSE
               k=Y*X/2-X/2+(j-1)*X/2+i
             ENDIF
             WRITE(102,10000) i,j,p(k)
           ENDDO
         ENDDO
c
         DO j=Y/gamma+1,Y
           DO i=1,X/2
             k=(j-1)*X/2+i
             WRITE(102,10000) i,j,p(k)
           ENDDO
         ENDDO
        CLOSE(102)
c
10000   FORMAT(2(I9,' '),3('  ',ES12.5))
10010   FORMAT(2(I9,' '),14X,3('  ',ES12.5))
C
      END SUBROUTINE Write_Out_uvp
c
c ======================================================================== 
c
      SUBROUTINE Write_Out_Psi
        USE Global_Var
c
        OPEN(UNIT=100,FILE=PsiOut,STATUS="REPLACE")
c
        DO j=1,Y+1
          DO i=1,X/2+1
            WRITE(100,10030)(i-1)*dx,(j-1)*dy,psi(i,j)
          ENDDO
        ENDDO
c
        DO j=1,Y/gamma+1
          DO i=X/2+2,X+1
            WRITE(100,10030)(i-1)*dx,(j-1)*dy,psi(i,j)
          ENDDO
        ENDDO
c
        CLOSE(100)
c
10030   FORMAT(3('  ',ES12.5))
      END SUBROUTINE Write_Out_Psi
c
c ======================================================================== 
c
      SUBROUTINE Write_Out_Div
        USE Global_Var
c
        OPEN(UNIT=100,FILE=DivOut,STATUS="REPLACE")
c
        DO j=1,Y
          DO i=1,X/2
c            WRITE(100,10030)(i-0.5)*dx,(j-0.5)*dy,div(i,j)
            WRITE(100,10040)i,j,div(i,j)
          ENDDO
        ENDDO
c
        DO j=1,Y/gamma
          DO i=X/2+1,X
c            WRITE(100,10030)(i-0.5)*dx,(j-0.5)*dy,div(i,j)
            WRITE(100,10040)i,j,div(i,j)
          ENDDO
        ENDDO
c
c
        CLOSE(100)
c
10030   FORMAT(3('  ',ES12.5))
10040   FORMAT(2(I3,3X),ES12.5)
      END SUBROUTINE Write_Out_Div
c
c ======================================================================== 
c
      SUBROUTINE Write_Out_CheckPoint
        USE Global_Var
c
        OPEN(UNIT=105,FILE=CheckOut,STATUS="REPLACE",
     $       FORM="UNFORMATTED")
c        REWIND(105)
        WRITE(105)Xm,h,X,Y,dt,eps,nu,Re,gamma
        WRITE(105)u_n
        WRITE(105)v_n
c        WRITE(105)psi
c        WRITE(105)p
c        WRITE(105)A
c        WRITE(105)IPIV
        CLOSE(105)
      END SUBROUTINE Write_Out_CheckPoint
c
c ======================================================================== 
c
      SUBROUTINE Read_In_CheckPoint
        USE Global_Var
        DOUBLE PRECISION :: c_Xm,c_h,c_dt,c_eps,c_nu,c_Re
        INTEGER :: c_X,c_Y,c_gamma
c
        OPEN(UNIT=105,FILE=CheckIn,STATUS="OLD",
     $       FORM="UNFORMATTED")
        READ(105)c_Xm,c_h,c_X,c_Y,c_dt,c_eps,c_nu,c_Re,c_gamma
        IF((c_Xm.ne.Xm).OR.(c_h.ne.h).OR.(c_X.ne.X).OR.(c_Y.ne.Y)
     $     .OR.(c_nu.ne.nu).OR.(c_gamma.ne.gamma).OR.(c_Re.ne.Re)) then
          WRITE(*,*)"Error: inconsistent checkpoint data"
          WRITE(*,*) "  OLD        = ", "     NEW ? "
          WRITE(*,10002)c_Xm,Xm
          WRITE(*,10002)c_h,h
          WRITE(*,10001)c_X,X
          WRITE(*,10001)c_Y,Y
          WRITE(*,10002)c_dt,dt
          WRITE(*,10002)c_eps,eps
          WRITE(*,10002)c_nu,nu
          WRITE(*,10002)c_Re,Re
          WRITE(*,10001)c_gamma,gamma          
          STOP
        ENDIF
        READ(105)u_n
        READ(105)v_n
c        READ(105)psi
c        READ(105)p
c        READ(105)A
c        READ(105)IPIV
        CLOSE(105)
10001   FORMAT(2(I9,"   "))
10002   FORMAT(2(ES12.5,"   "))
c
      END SUBROUTINE Read_In_CheckPoint
c
c
c =========================================================================
c
       LOGICAL FUNCTION Converge()
          USE Global_Var
          DOUBLE PRECISION :: udiff,vdiff,temp
          INTEGER :: iu,ju,iv,jv
c
          udiff=0.0
          vdiff=0.0
c
          DO j=1,Y
             DO i=1,X/2
                temp=ABS(u_n_plus_1(i,j)-u_n(i,j))/dt
                IF (temp.GT.udiff) THEN
                   udiff=temp
                   iu=i;ju=j
                ENDIF
                temp=ABS(v_n_plus_1(i,j)-v_n(i,j))/dt
                IF (temp.GT.vdiff) THEN
                   vdiff=temp
                   iv=i;jv=j
                ENDIF

             ENDDO
          ENDDO
c
          DO j=1,Y/gamma
             DO i=X/2+1,X
                temp=ABS(u_n_plus_1(i,j)-u_n(i,j))/dt
                IF (temp.GT.udiff) THEN
                   udiff=temp
                   iu=i;ju=j
                ENDIF
                temp=ABS(v_n_plus_1(i,j)-v_n(i,j))/dt
                IF (temp.GT.vdiff) THEN
                   vdiff=temp
                   iv=i;jv=j
                ENDIF
             ENDDO
          ENDDO
c
          IF ((udiff.GT.eps).OR.(vdiff.GT.eps)) THEN 
             Converge=.FALSE.
          ELSE
             Converge=.TRUE.
          ENDIF
c
          if(mod(n,iinfo).eq.0)WRITE(*,10010)n,udiff,iu,ju,
     $                                         vdiff,iv,jv
10010     FORMAT("n=",I6,"   udiff=",ES12.4," (",I3,",",I3,")",
     $                   "   vdiff=",ES12.4," (",I3,",",I3,")")
c
       END FUNCTION Converge
c
c =========================================================================
c
       SUBROUTINE Print_IPIV
          USE Global_Var
          OPEN(UNIT=101,FILE="Row.Swap",STATUS="REPLACE")
          DO i=1,Y*X/2+Y/gamma*X/2
             WRITE(101,*)i,IPIV(i)
          ENDDO
          CLOSE(101)
       END SUBROUTINE Print_IPIV
c
c =========================================================================
c
       SUBROUTINE Singular
          USE Global_Var
          OPEN(UNIT=103,FILE="Singular.vals",STATUS="REPLACE")
          DO i=1,Y*X/2+Y/gamma*X/2
             WRITE(103,*)i,S(i)
          ENDDO
          CLOSE(103)
       END SUBROUTINE Singular
c
c =========================================================================
c
c =========================================================================
c
      PROGRAM Step
      
        USE Global_Var 
         LOGICAL, EXTERNAL :: Converge
         CALL Input_Data
         CALL Alloc_Arrays
         PRINT *,"Forming PPE matrix"
           CALL Matrix
c           CALL Check_Matrix
c           CALL DGESVD('A','A',Y*X/2+Y/gamma*X/2,
c     $             Y*X/2+Y/gamma*X/2,A,Y*X/2+Y/gamma*X/2,S,UPP,
c     $             Y*X/2+Y/gamma*X/2,VTT,Y*X/2+Y/gamma*X/2,WORK,
c     $             5*(Y*X/2+Y/gamma*X/2)-4,INFO)
c           CALL Singular
c           CALL Matrix
         PRINT *,"Calculating LU decomposition of PPE matrix"
           CALL DGETRF(Y*X/2+Y/gamma*X/2,Y*X/2+Y/gamma*X/2,
     $                  A,Y*X/2+Y/gamma*X/2,IPIV,INFO)
c           CALL Print_IPIV
         IF(info.ne.0)THEN
           PRINT *,"Error on LU decomposition: info=",info
           stop
         ENDIF
         IF(CheckIn.ne."")THEN
           PRINT *,"Reading checkpoint data"
           CALL Read_In_CheckPoint
         ELSE
           CALL ic(u_n,v_n)
         ENDIF
         PRINT *,"Starting time step loop"
         n=0
         DO 
            n=n+1
            CALL UV_Stars 
            CALL Rhs_Column
            CALL DGETRS('N',Y*X/2+Y/gamma*X/2,1,A,
     $         Y*X/2+Y/gamma*X/2,IPIV,p,Y*X/2+Y/gamma*X/2,INFO)
            CALL UV_n_plus_1
            CALL CopyVals_Star
            IF (Converge()) THEN 
               PRINT *,"Converged after time step",n
               EXIT
            ENDIF
            IF(n.eq.maxstep) THEN
               PRINT *,"FAILED to converge in maximum time steps",n
               EXIT
            ENDIF
            CALL CopyVals
         ENDDO
         CALL CopyVals
         CALL Calc_Psi
         CALL Calc_Div 
c         CALL Write_Out_uvp
         CALL Write_Out_Psi
         CALL Write_Out_Div 
c         CALL Separation_PsiMax_Points
         CALL Wvorticity
         IF(CheckOut.ne."")CALL Write_Out_CheckPoint 
c
      END PROGRAM Step
c
c ========================================================================
c
c ========================================================================
