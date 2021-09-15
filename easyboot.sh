#!/bin/bash
expert_mode() {
  win=$1
  force=$2
  BOOT_SEQ=""
  BOOT_OPT="-n"
  win="0006"
  pos="0003"
  BOOT_OS=""
  POSITIONAL=()
  usage() {
    echo -e "boot2os.sh <win|pos> [options]\n\
    -f or --force for permanent boot the OS\n\
    -h or --help to print this help"
  }
  while [[ $# -gt 0 ]]; do
    key="$1"

    case $key in
      -f|--force)
        BOOT_OPT="-o"
        shift # past argument      
        ;;
      win|pos)
        BOOT_OS="$1"
        shift # past argument
        ;;
      -h|--help)
    print_help
    shift #
    exit 0
        ;;
      *)    # unknown option
        POSITIONAL+=("$1") # save it in an array for later
        usage
        shift # past argument
        ;;
    esac
  done

  [[ "${BOOT_OS}" == "" ]] && echo "Missing OS input" && exit 1

  echo "Echo set one time boot to Window 10 or Zorin OS"

  eval BOOT_NUM='$'$BOOT_OS
  BOOT_MSG="Making one time booting to"
  if [[ $BOOT_OPT == "-o" ]]; then
    BOOT_ORDER="$(sudo efibootmgr | sed -rn "s/BootOrder\:\s(.*)/\1/p")"
    BOOT_SEQ=",$(echo $BOOT_ORDER | sed -rn "s/${BOOT_NUM}\,//p")"
    
    BOOT_MSG="Making permanent booting to"
  fi

  BOOT_OS_NAME=$(sudo efibootmgr | sed -rn "s/Boot${BOOT_NUM}\*\s//p")
  BOOT_ARGS="${BOOT_OPT} ${BOOT_NUM}${BOOT_SEQ}"
  echo "efibootmgr $BOOT_ARGS"
  sudo efibootmgr $BOOT_ARGS

  echo -e "\n\nDone - ${BOOT_MSG} ${BOOT_OS_NAME}\n\n"
}


user_mode() {
  boot_oses=()
  readarray -t -O "${#boot_oses[@]}" boot_oses < <( efibootmgr | grep -P "Boot\d+\*" )
  menu_item=1
  echo "Please select boot entry:"
  for boot_os in "${boot_oses[@]}"
  do
    echo -e "\t[$(printf "%2d" $menu_item)] ${boot_os}"    
    let "menu_item+=1";
  done;
  
  echo
  select_option 1 ${#boot_oses[@]}
  BOOT_NUM=$?
  let "BOOT_NUM-=1"
  boot_entry=${boot_oses[BOOT_NUM]}
  BOOT_NUM=$(echo $boot_entry | sed -rn "s/Boot([0-9]+)\*.*/\1/p")
  echo "Selected boot entry: $boot_entry"

  echo
  select_boot_option
  input=$?
  BOOT_OS_NAME=$(sudo efibootmgr | sed -rn "s/Boot${BOOT_NUM}\*\s//p")
  BOOT_ARGS=""
  case $input in
    1)  
      echo "Selected boot option: One time boot"
      BOOT_ORDER="$(efibootmgr | sed -rn "s/BootOrder\:\s(.*)/\1/p")"
      BOOT_ARGS="-n ${BOOT_NUM}"
      ;;
    2)
      echo "Selected boot option: Permanent boot"
      BOOT_ORDER="$(efibootmgr | sed -rn "s/BootOrder\:\s(.*)/\1/p")"
      BOOT_SEQ=",$(echo $BOOT_ORDER | sed -rn "s/${BOOT_NUM}\,//p")"
      BOOT_ARGS="-o ${BOOT_NUM}${BOOT_SEQ}"
      ;;
    *) 
      echo "Opps something went wrong, unable to detect your boot option"
      exit 1;      
  esac
  echo -e "\n\n\n"
  sudo efibootmgr $BOOT_ARGS
}

select_option() {
  min=$1
  max=$2
  while true; do
    read -p "Please input your selection [$min-$max]: " input
    if [[ $input ]] && [ $input -eq $input 2>/dev/null ] && (( $input >= $min  )) && (( $input <= $max ))
    then
      return $input
    else
      echo "Opps $input is not an invalid option"
    fi
  done
}

select_boot_option() {
  echo "Please choose your boot options"
  echo -e "\t[1] One time boot"
  echo -e "\t[2] Permanent boot"

  select_option 1 2
}

if [ $# -eq 0 ]
then
    user_mode
else
    expert_mode $@
fi
