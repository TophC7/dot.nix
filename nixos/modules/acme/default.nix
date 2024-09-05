{
    # TODO: find out how to add the certs from my nginx doxker since this jurs errors always

    # letsencrypt this wont do shit but allows things to work
    # i take care of this on dockge lxc
    security.acme = {
        acceptTerms = true;
        defaults.email = "chris@toph.cc";
    };
}