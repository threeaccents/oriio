# Oriio 

Oriio is an all-in-one HTTP service for file uploading, processing, serving, and storage. Oriio supports chunked, resumable, and concurrent uploads. Oriio uses Libvips behind the scenes making it extremely fast and memory efficient.

Oriio currently supports any s3 compatible storage, which includes (AWS s3, DO Spaces, Wasabi, Backblaze B2). The specific storage engine can be set in the config.

Oriio is also distributed using Erlang's built in clustering and DeltaCrdt for syncing state between the cluster.

## Features
 - [Uploads](https://github.com/threeaccents/oriio#uploads) upload files easily via our Web API.
 - [Chunked, Concurrent, Resumable Uploads](https://github.com/threeaccents/oriio#large-file-uploads) upload large files by chunking them and uploading them to our Web API.
 - [Distributed](#) run in cluster
 - [Fault Taulerant](#) distributed process handoff, with process state handoff.
 - [Signed Uploads](#) Secure uploads from your front end application.
 - [Flexible File Storage](https://github.com/threeaccents/oriio#applications) store your files in S3, Spaces, Wasabi, B2 with more options coming soon.
 - [Image Processing](https://github.com/threeaccents/oriio#file-transformations) resize, convert, and crop with ease.

## Install 
Libvips must be installed on your machine. 
### Ubuntu
```bash
sudo apt install libvips libvips-dev libvips-tools
```
### MacOS
```bash
brew install vips
```
For other systems check out instructions [here](https://github.com/libvips/libvips/wiki#building-and-installing).

## Uploads
Files are uploaded to Oriio via `multipart/form-data` requests. Along with passing in the file data, you must also provide the `application_id`.
Oriio will handle processing and storing the file blob in the application's storage engine along with storing the file meta-data in the database.
To view an example upload response check out the [Web API](https://oriio-api-docs.threeaccents.com/#req_25f7dce3e796456e9f80ce43deba705b)

## Large File Uploads
When dealing with large files, it is best to split the file into small chunks and upload each chunk separately. Oriio easily handles chunked uploads storing each chunk and then re-building the whole file. Once the whole file is re-built Oriio uploads the file to the application's storage engine.
To view an example upload response check out the [Web API](https://oriio-api-docs.threeaccents.com/#req_649a25397026402b82397975292fbc4f)

Other benefits of chunking up files are the ability to resume uploads and uploading multiple chunks concurrently. Oriio handles both scenarios for you with ease.

## Signed Uploads
todo

## File Transformations (More Coming Soon)
Oriio supports file transformations via URL query params. Currently, the supported operations are:
 - Resize (width, height) `?width=100&height=100`
 - Smart Crop `?crop=true`
 - Flip `?flip=true`
 - Flop `?flop=true`
 - Zoom `?zoom=2`
 - Black and White `?bw=true`
 - Quality(JPEG), Compression(PNG) `?quality=100` `?compression=10`
 - Format conversion `format is based on the file extension. To transform a png to webp, just use the .webp extension.`

All queries can be used together. For example, to resize the width, make the image black and white, and change the format to webp the params would look like this:
```
https://yourdomain.com/myimage.webp?width=100&bw=true
```

## Distributed
TODO

## Fault Taulerant
TODO


