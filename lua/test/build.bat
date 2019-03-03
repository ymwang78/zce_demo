@echo off

.\protoc.exe addressbook.proto --descriptor_set_out=addressbook.pb

@pause