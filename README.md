# easyboot
Easyboot modify next boot times

## Usage

To enter user mode
```
  bash ./easyboot.sh
```

To enter a quick mode

```
  bash ./easyboot.sh win -f
```
or print out the usage

```
  bash ./easyboot.sh -h
```

### Note

You have to modify the script to input which boot number to these 2 varables
```
win="0006"
pos="0003"
```
Execute this command to figure out boot num
```
efibootmgr
```
