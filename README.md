# About handbrake-scheduler.sh

- A bash script to encode video files in a directory and its subdirectories using **HandBrakeCLI**. The output file will also have the same directory structure as the source directory.
- The files in source directory can be moved to another location or can be sent to /dev/null. This will prevent re-encoding the files again if the script is called on the folder twice. (ie If you schedule it with cronTab etc)

## Change HandBrakeCLI options:

Edit the handbrake-scheduler.sh/start_encode() to add HandBrakeCLI options. (Hard coded for now)
The default options are: -e x265 -q 22 -r 60 -w 1920 -l 1080 --verbose=2
```
echo "" | HandBrakeCLI -i "$input_file_path" -o "$output_file_path" <YOUR OPTIONS GOES HERE> >> "$log_path" 2>&1
```

## Example Script:

The basic script looks like this.
```
./handbrake-scheduler.sh -i /path/of/source/dir/ -o /path/of/output/dir/ -m /path/of/movedSource/dir -l /path/of/log/dir
```
