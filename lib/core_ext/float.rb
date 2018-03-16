class Float

  def pct_string
    if self < 0.001
      "< 0.1%"
    else
      "#{(self*100).round(2)}%"
    end
  end
end
