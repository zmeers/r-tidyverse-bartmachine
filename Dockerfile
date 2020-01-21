FROM rocker/verse:latest
MAINTAINER Zoe Meers zoe.meers@gmail.com

# grab data and install remotely

RUN install2.r lubridate

RUN mkdir /home/data_prep

COPY nowcasting_538.R /home/data_prep/nowcasting_538.R

COPY data_prep_2020.R /home/data_prep/data_prep_2020.R

CMD R -e "source('/home/data_prep/nowcasting_538.R')"

CMD R -e "source('/home/data_prep/data_prep_2020.R')"




# Rstan and friends

# RUN apt-get update \
#	&& apt-get install -y --no-install-recommends apt-utils ed libnlopt-dev \
#    && apt-get clean \
#    && rm -rf /var/lib/apt/lists/

# Install rstan
#RUN install2.r --error --deps TRUE \
#    rstan 

# Global site-wide config -- neeeded for building packages
#RUN mkdir -p $HOME/.R/ \
#    && echo "CXXFLAGS=-O3 -mtune=native -march=native -Wno-unused-variable -Wno-unused-function -flto -ffat-lto-objects  -Wno-unused-local-typedefs \n" >> $HOME/.R/Makevars

# Config for rstudio user
#RUN mkdir -p $HOME/.R/ \
#    && echo "CXXFLAGS=-O3 -mtune=native -march=native -Wno-unused-variable -Wno-unused-function -flto -ffat-lto-objects  -Wno-unused-local-typedefs -Wno-ignored-attributes -Wno-deprecated-declarations\n" >> $HOME/.R/#Makevars \
#    && echo "rstan::rstan_options(auto_write = TRUE)\n" >> /home/rstudio/.Rprofile \
#    && echo "options(mc.cores = parallel::detectCores())\n" >> /home/rstudio/.Rprofile

# Install rstan
#RUN install2.r --error --deps TRUE \
#    rstan \
#	loo \
#	bayesplot \
#    rstanarm \
#    rstantools \
#    shinystan 

# Install packages for remote analysis 

RUN install2.r doFuture future.callr furrr doParallel doMC doRNG bartMachine ModelMetrics \
    && rm -rf /tmp/downloaded_packages/ /tmp/*.rds

