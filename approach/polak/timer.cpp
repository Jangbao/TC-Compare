#include "timer.h"

#include <chrono>
#include <iostream>
#include <iomanip>
using namespace std;

namespace
{
  class TimerImpl : public Timer
  {
  public:
    TimerImpl() : last(Clock::now()) {}
    virtual ~TimerImpl() {}

    virtual int Done(const char *label)
    {
      Clock::time_point now = Clock::now();
      int res = chrono::duration_cast<chrono::microseconds>(now - last).count();
      last = now;
      float time = res;
      // cerr << label << " " << fixed << setprecision(3) << time / 1000 << " ms" << endl;
      return res;
    }

    virtual void Reset()
    {
      last = Clock::now();
    }

    typedef std::chrono::high_resolution_clock Clock;

  private:
    Clock::time_point last;
  };
} // namespace

Timer *Timer::NewTimer() { return new TimerImpl; }
