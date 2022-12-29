#!/bin/bash

_do_signals() {
    if [ ! -z "$signal" ] ; then
        echo "SignalProxy.sh caught signal $signal"
        for p in ${sp_processes[@]}
            do
                pkill --signal $signal $p
            done
    fi
}


trap "_do_signals SIGHUP" SIGHUP
trap "_do_signals SIGINT" SIGINT
trap "_do_signals SIGQUIT" SIGQUIT
trap "_do_signals SIGILL" SIGILL
trap "_do_signals SIGTRAP" SIGTRAP
trap "_do_signals SIGABRT" SIGABRT
trap "_do_signals SIGBUS" SIGBUS
trap "_do_signals SIGFPE" SIGFPE
trap "_do_signals SIGKILL" SIGKILL
trap "_do_signals SIGUSR1" SIGUSR1
trap "_do_signals SIGSEGV" SIGSEGV
trap "_do_signals SIGUSR2" SIGUSR2
trap "_do_signals SIGPIPE" SIGPIPE
trap "_do_signals SIGALRM" SIGALRM
trap "_do_signals SIGTERM" SIGTERM
trap "_do_signals SIGSTKFLT" SIGSTKFLT
#trap "_do_signals SIGCHLD" SIGCHLD
trap "_do_signals SIGCONT" SIGCONT
trap "_do_signals SIGSTOP" SIGSTOP
trap "_do_signals SIGTSTP" SIGTSTP
trap "_do_signals SIGTTIN" SIGTTIN
trap "_do_signals SIGTTOU" SIGTTOU
trap "_do_signals SIGURG" SIGURG
trap "_do_signals SIGXCPU" SIGXCPU
trap "_do_signals SIGXFSZ" SIGXFSZ
trap "_do_signals SIGVTALRM" SIGVTALRM
trap "_do_signals SIGPROF" SIGPROF
trap "_do_signals SIGWINCH" SIGWINCH
trap "_do_signals SIGIO" SIGIO
trap "_do_signals SIGPWR" SIGPWR
trap "_do_signals SIGSYS" SIGSYS
trap "_do_signals SIGRTMIN" SIGRTMIN
trap "_do_signals SIGRTMIN+1" SIGRTMIN+1
trap "_do_signals SIGRTMIN+2" SIGRTMIN+2
trap "_do_signals SIGRTMIN+3" SIGRTMIN+3
trap "_do_signals SIGRTMIN+4" SIGRTMIN+4
trap "_do_signals SIGRTMIN+5" SIGRTMIN+5
trap "_do_signals SIGRTMIN+6" SIGRTMIN+6
trap "_do_signals SIGRTMIN+7" SIGRTMIN+7
trap "_do_signals SIGRTMIN+8" SIGRTMIN+8
trap "_do_signals SIGRTMIN+9" SIGRTMIN+9
trap "_do_signals SIGRTMIN+10" SIGRTMIN+10
trap "_do_signals SIGRTMIN+11" SIGRTMIN+11
trap "_do_signals SIGRTMIN+12" SIGRTMIN+12
trap "_do_signals SIGRTMIN+13" SIGRTMIN+13
trap "_do_signals SIGRTMIN+14" SIGRTMIN+14
trap "_do_signals SIGRTMIN+15" SIGRTMIN+15
trap "_do_signals SIGRTMAX-14" SIGRTMAX-14
trap "_do_signals SIGRTMAX-13" SIGRTMAX-13
trap "_do_signals SIGRTMAX-12" SIGRTMAX-12
trap "_do_signals SIGRTMAX-11" SIGRTMAX-11
trap "_do_signals SIGRTMAX-10" SIGRTMAX-10
trap "_do_signals SIGRTMAX-9" SIGRTMAX-9
trap "_do_signals SIGRTMAX-8" SIGRTMAX-8
trap "_do_signals SIGRTMAX-7" SIGRTMAX-7
trap "_do_signals SIGRTMAX-6" SIGRTMAX-6
trap "_do_signals SIGRTMAX-5" SIGRTMAX-5
trap "_do_signals SIGRTMAX-4" SIGRTMAX-4
trap "_do_signals SIGRTMAX-3" SIGRTMAX-3
trap "_do_signals SIGRTMAX-2" SIGRTMAX-2
trap "_do_signals SIGRTMAX-1" SIGRTMAX-1
trap "_do_signals SIGRTMAX" SIGRTMAX
