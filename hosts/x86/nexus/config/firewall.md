WHAT I NEED

NETWORKS:
- NEXUS (virtual)
- NIMBUS (nas nimbus pc, has the nic too)
- ZEBES (most *.ryot.foo services are here)
- RUNE (trusted network, my pc)
- HAZE (more isolated)

LEGEND FOR CONNECTION IN GENERAL, NOT PORTS:

SEND TO -> (as in tries to UPLOAD to b for example)
RECEIVE FROM <- (a tries to DOWNLOAD from b)
BOTH <->
BLOCK /

ALLOW:

NEXUS <-> ALL
NIMBUS <-> ALL
ZEBES <-> NIMBUS, NEXUS
RUNE -> ALL
RUNE <- NONE
HAZE <-> NIMBUS, NEXUS

PORTS IN NEXUS:
The NEXUS network (virtual 104.40.1.0/24) should only be accessible through the ports of gerbil, nowhere else

THIS is a bit confusing to, explain back to me what you understood, but in the correct firewall terms