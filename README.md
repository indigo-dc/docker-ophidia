# docker-ophidia
Docker image to run Ophidia framework
All services in image

## Further documentation

* Ophidia: http://ophidia.cmcc.it/documentation/
* Installation and configuration: http://ophidia.cmcc.it/documentation/admin/index.html

## Run the docker image

```
$ docker run ophidia_all
```

## The following commands define a complete test session that can be run through the Ophidia terminal

```
oph_term> oph_list level=2;
oph_term> oph_man function=oph_list;
oph_term> oph_createcontainer container=test;dim=lat|lon|time;hierarchy=oph_base|oph_base|oph_time;dim_type=double|double|double;
oph_term> oph_randcube container=test;dim=lat|lon|time;dim_size=10|10|10;measure=test;measure_type=double;nfrag=10;ntuple=10;concept_level=c|c|d;exp_ndim=2;compressed=no; 
oph_term> oph_cubeschema
oph_term> oph_reduce operation=max;
oph_term> oph_aggregate operation=max;
oph_term> oph_explorecube
oph_term> oph_delete cube=[container=test];
```

