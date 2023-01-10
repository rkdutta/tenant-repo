#!/bin/bash  

# for base 

echo "syntax: ./base.sh runFor[base or variant or tenant] basePath[base/ or tenants/] tenant[kla] environment[acc or dev]"

runFor=$1 # base or tenant
basePath="$2"
updateStratey=$3
environment="$4"
tenant="$5"


if [[ -z "$runFor" ]]; then
 echo "missing input runFor [base or variant or tenant]"
 exit 1;
fi

if [[ -z "$basePath" ]]; then
 echo "missing input basePath"
 exit 1;
fi


if [[ "$runFor" == "base" ]]; then 
    cd $basePath
    rm -f kustomization.yaml
    kustomize init
elif [[ "$runFor" == "variant" && "$environment" != "" ]]; then 
    cd $basePath/$environment
    pwd
    rm -f kustomization.yaml
    kustomize init
    kustomize edit add resource "../../base"
    kustomize edit set namespace $environment
elif [[ "$runFor" == "tenant" && "$environment" != "" ]]; then 
    cd $basePath/$tenant/$environment
    rm -f kustomization.yaml
    kustomize init
    kustomize edit add resource "../../../variants/$environment"
    kustomize edit set namespace $environment
else
    echo "Unsupported -  $runFor / $basePath / $environment"
    exit 1
fi

for dir in */ ; do
    echo "Processing in $dir"

    for file in $dir*; 
    do 
        echo "Processing $file file..."
        
        fileNameWithOutPath=`basename $file`
        fileNameExtn=${fileNameWithOutPath##*.}
        fileNameWithOutPathAndExtn=`basename $file .$fileNameExtn`
   
        if [[ $dir == "envs/" ]]; then
            kustomize edit add configmap $fileNameWithOutPathAndExtn --behavior=$updateStratey --from-env-file=$file --disableNameSuffixHash
        elif [[ $dir == "files/" ]]; then
            kustomize edit add configmap $fileNameWithOutPathAndExtn --behavior=$updateStratey --from-file=$file --disableNameSuffixHash
        elif [[ $dir == "values/" ]]; then
            kustomize edit add configmap $fileNameWithOutPathAndExtn --behavior=$updateStratey --from-file=values.yaml=$file --disableNameSuffixHash
        else
            echo "Unsupported directory structure -  $dir"
            exit 1
        fi
    done
done
