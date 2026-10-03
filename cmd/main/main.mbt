///|
extern "js" fn read_input() -> String =
  #|() => require('node:fs').readFileSync(0, 'utf8')

///|
extern "js" fn fail_exit() -> Unit =
  #|() => { process.exitCode = 2; }

///|
fn main {
  let result = @ledger.run(read_input())
  println(result.0)
  if !result.1 {
    fail_exit()
  }
}
