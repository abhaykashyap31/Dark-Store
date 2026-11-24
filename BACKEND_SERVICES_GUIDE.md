def Calculator(strParam):
    s = strParam.replace(" ", "")
    n = len(s)
    pos = 0

    def peek():
        return s[pos] if pos < n else ''

    def expr():
        nonlocal pos
        val = term()
        while peek() in ('+', '-'):
            op = s[pos]
            pos += 1
            rhs = term()
            val = val + rhs if op == '+' else val - rhs
        return val

    def term():
        nonlocal pos
        val = factor()
        while True:
            c = peek()
            if c == '*':
                pos += 1
                val *= factor()
            elif c == '/':
                pos += 1
                val = val // factor()
            elif c == '(' or c.isdigit():
                # implicit multiplication, e.g. (2-0)(6/2) or 2(3)
                val *= factor()
            else:
                break
        return val

    def factor():
        nonlocal pos
        c = peek()
        if c == '-':              # unary minus
            pos += 1
            return -factor()
        if c == '+':
            pos += 1
            return factor()
        if c == '(':
            pos += 1
            val = expr()
            pos += 1              # skip ')'
            return val
        start = pos
        while pos < n and s[pos].isdigit():
            pos += 1
        return int(s[start:pos])

    return expr()

# keep this function call here
print(Calculator(input()))